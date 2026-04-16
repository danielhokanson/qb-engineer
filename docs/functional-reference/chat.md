# Chat

## Overview

Chat provides built-in real-time messaging between users of the application. It supports 1:1 direct messages (DMs) and group chat rooms. Messages are delivered in real-time via the `ChatHub` SignalR hub and persisted in the database for offline retrieval. The chat panel is a slide-out overlay accessible from the application header, not a standalone page route.

The system is designed for lightweight internal communication between team members -- shop floor workers, engineers, managers, and admins -- without requiring an external messaging tool.

---

## Routes

| Path | Component | Notes |
|------|-----------|-------|
| `/chat` | `ChatComponent` | Lazy-loaded route. In practice, the chat feature is surfaced as a slide-out panel toggled from the header, not navigated to as a page. |

The route file defines a single catch-all route:

```typescript
export const CHAT_ROUTES: Routes = [{ path: '', component: ChatComponent }];
```

---

## Architecture

### Panel Layout

The chat panel is a fixed-position overlay anchored to the right edge of the viewport, below the application header. It uses the `$notification-panel-width` (380px) width, matching the notification panel. On mobile (`$breakpoint-mobile`), it expands to full width.

The panel has three states:

1. **Conversation list** -- shows all DM conversations with the current user, ordered by most recent message.
2. **User picker** -- allows starting a new DM by searching and selecting a user.
3. **Message view** -- shows the message history for a selected conversation with a text input at the bottom.

A semi-transparent backdrop sits behind the panel. Clicking the backdrop or the close button toggles the panel closed.

### Data Flow

- **Open panel** -> `loadConversations()` -> `GET /api/v1/chat/conversations` -> populate conversation list + compute `totalUnread`.
- **Select conversation** -> `loadMessages(otherUserId)` -> `GET /api/v1/chat/messages/{otherUserId}` -> display messages + auto-mark as read via `POST /api/v1/chat/messages/{otherUserId}/read`.
- **Send message** -> `POST /api/v1/chat/messages` -> append to local message list + clear input.
- **Receive message (SignalR)** -> `messageReceived` event -> append to message list if the sender/recipient matches the active conversation -> auto-mark as read -> refresh conversation list.

---

## Conversation List

When the panel opens, the service fetches all conversations for the authenticated user. Each conversation represents a unique 1:1 DM thread with another user.

### Conversation Card

Each conversation displays:

| Element | Source | Notes |
|---------|--------|-------|
| Avatar | `userInitials` + `userColor` | `AvatarComponent` at `size="sm"` |
| User name | `userName` | Truncated with ellipsis |
| Last message preview | `lastMessage` | Single line, truncated |
| Relative timestamp | `lastMessageAt` | Formatted as relative time (see below) |
| Unread badge | `unreadCount` | Accent-colored badge, hidden when 0 |

### Relative Timestamp Formatting

| Elapsed Time | Display |
|-------------|---------|
| < 1 minute | "Just now" (i18n: `chat.justNow`) |
| 1--59 minutes | `{n}m` |
| 1--23 hours | `{n}h` |
| 1--6 days | `{n}d` |
| 7+ days | `MM/dd/yyyy` (via `formatDate` util) |

### Empty State

When no conversations exist, the panel shows a centered empty state with a `chat_bubble_outline` icon and the text `chat.noConversations`.

### New Conversation Button

A full-width primary button labeled "New Message" (`chat.newMessage`) sits above the conversation list. Clicking it opens the user picker.

---

## User Picker (New Conversation)

The user picker allows starting a DM with any active user in the system.

### Behavior

1. On first open, fetches all users from `GET /api/v1/users`.
2. Caches the user list in memory for the panel session.
3. Filters out the current user and any users who already have an existing conversation.
4. Supports live filtering by name via a search input.

### Search Input

| Field | Type | Notes |
|-------|------|-------|
| Search users | Text input | Autofocused on open. Placeholder: `chat.searchUsers`. |

### User List

Each user is displayed as a button with an avatar and name, styled identically to conversation cards. Clicking a user:

1. Creates a `ChatConversation` stub (with empty `lastMessage` and `unreadCount: 0`).
2. Sets it as the selected conversation.
3. Loads messages for that user (which will be empty if no prior DMs exist).
4. Closes the user picker and shows the message view.

### Cancel

A close icon button in the search bar returns to the conversation list.

---

## Message Area

### Message Display

Messages are rendered in a scrollable container with the following structure:

| Element | Class | Notes |
|---------|-------|-------|
| Date separator | `message-date-separator` | Shown at day boundaries between messages |
| Received message | `message` | Left-aligned, with sender avatar |
| Sent message | `message message--own` | Right-aligned, primary-light background with primary border |

#### Date Separators

A horizontal line with a centered date label appears when messages cross a day boundary:

| Condition | Label |
|-----------|-------|
| Today | Not shown (first message of today has no separator) |
| Yesterday | "Yesterday" |
| Older | e.g., "Mon, Mar 9, 2026" (`weekday: 'short', month: 'short', day: 'numeric', year: 'numeric'`) |
| First message in history (not today) | Shows the date label |

#### Message Bubble

Each message bubble contains:

- **Content** (`message__text`) -- preserves whitespace (`white-space: pre-wrap`) and breaks long words.
- **Timestamp** (`message__time`) -- formatted as `HH:MM` (2-digit hour:minute, locale-aware).

For received messages, the sender's avatar (`AvatarComponent`, `size="sm"`) is shown to the left of the bubble. For sent messages, the avatar is omitted and the bubble is right-aligned.

#### Message Width

Messages have a maximum width of 85% of the container.

### Auto-Scroll

After loading messages or receiving a new message, the container scrolls to the bottom via `scrollToBottom()` using `setTimeout` to allow DOM rendering.

---

## Message Input

| Field | Type | data-testid | Notes |
|-------|------|-------------|-------|
| Message input | Text input | `chat-message-input` | Placeholder: `chat.typeMessage`. Full width minus send button. |
| Send button | Icon button | `chat-send-btn` | `send` icon. Disabled when input is empty or whitespace-only. |

### Keyboard Shortcut

- **Enter** sends the message (calls `sendMessage()`).
- **Shift+Enter** inserts a newline (default browser behavior for the input).

### Send Behavior

1. Trims the input value.
2. Calls `POST /api/v1/chat/messages` with `{ recipientId, content }`.
3. Appends the returned `ChatMessageResponseModel` to the local message list.
4. Clears the input.
5. Scrolls to the bottom.

---

## SignalR Real-Time (ChatHub)

### Hub Endpoint

`/hubs/chat` -- requires `[Authorize]`. JWT is passed via the `?access_token=` query string parameter (standard SignalR WebSocket auth).

### Connection Lifecycle

| Event | Behavior |
|-------|----------|
| `OnConnectedAsync` | Adds the connection to a SignalR group named `user:{userId}` |
| `OnDisconnectedAsync` | Removes the connection from the `user:{userId}` group |

### Client Methods (Hub -> Client)

| Method | Payload | When |
|--------|---------|------|
| `messageReceived` | `ChatMessageEvent` | A new DM is sent to the user (or by the user from another tab) |

### Server Methods (Client -> Hub)

| Method | Parameters | Purpose |
|--------|-----------|---------|
| `JoinRoom` | `roomId: int` | Subscribe to a chat room's messages (group rooms) |
| `LeaveRoom` | `roomId: int` | Unsubscribe from a chat room |

### Frontend Connection

The `ChatHubService` wraps `SignalrService` for the `chat` hub:

- Connects on first panel open.
- Disconnects in `ngOnDestroy`.
- Registers a single `messageReceived` handler that:
  1. Checks if the sender or recipient matches the active conversation.
  2. If yes, appends the message to the local list, sorts by `createdAt`, scrolls to bottom, and auto-marks as read.
  3. Refreshes the conversation list regardless (to update unread counts and ordering).

### Broadcasting (Server-Side)

When a message is sent via `POST /api/v1/chat/messages`, the `SendMessageHandler`:

1. Persists the `ChatMessage` entity.
2. Broadcasts a `ChatMessageEvent` to the recipient's SignalR group (`user:{recipientId}`) via `IHubContext<ChatHub>`.

---

## Group Chat Rooms (API Ready, UI Partial)

The backend fully supports group chat rooms. The frontend `ChatService` exposes the group room API methods, but the UI currently only renders 1:1 DM conversations.

### Group Room API Methods (ChatService)

| Method | HTTP | Endpoint |
|--------|------|----------|
| `getChatRooms()` | GET | `/api/v1/chat/rooms` |
| `createChatRoom(name, memberIds)` | POST | `/api/v1/chat/rooms` |
| `getChatRoomMessages(roomId, page, pageSize)` | GET | `/api/v1/chat/rooms/{roomId}/messages` |
| `sendChatRoomMessage(roomId, content)` | POST | `/api/v1/chat/rooms/{roomId}/messages` |
| `addRoomMember(roomId, userId)` | POST | `/api/v1/chat/rooms/{roomId}/members/{userId}` |
| `removeRoomMember(roomId, userId)` | DELETE | `/api/v1/chat/rooms/{roomId}/members/{userId}` |

### Room Entity

A `ChatRoom` has a `Name`, `IsGroup` boolean, `CreatedById`, and a collection of `ChatRoomMember` records. The creator is automatically added as a member.

---

## File Sharing (Entity Model Ready, UI Not Built)

The `ChatMessage` entity includes fields for file and entity sharing, but the UI does not currently render or upload these:

| Field | Type | Notes |
|-------|------|-------|
| `FileAttachmentId` | `int?` | FK to `FileAttachment` entity |
| `FileAttachment` | Navigation | Full file metadata (fileName, contentType, size, url) |
| `LinkedEntityType` | `string?` | Entity type for cross-entity links (e.g., "Job", "Part") |
| `LinkedEntityId` | `int?` | Entity ID for the linked entity |

The frontend `ChatMessage` model includes `fileAttachment: ChatFileAttachment | null` and `linkedEntityType: string | null` / `linkedEntityId: number | null`, but these fields are always `null` in the current DM implementation.

### ChatFileAttachment Interface

```typescript
interface ChatFileAttachment {
  id: number;
  fileName: string;
  contentType: string;
  size: number;
  url: string;
}
```

---

## Form Fields

### Message Input

| Field | Control Type | Validation | data-testid |
|-------|-------------|------------|-------------|
| Message text | `FormControl('')` | Not empty after trim (enforced in `sendMessage()`) | `chat-message-input` |

### User Search (User Picker)

| Field | Control Type | Validation |
|-------|-------------|------------|
| Search users | `FormControl('')` | No validation; used for client-side filtering only |

### Send Message Request Body

| Field | Type | Validation (Server) |
|-------|------|-------------------|
| `recipientId` | `int` | > 0 |
| `content` | `string` | Not empty, max 4000 characters |

### Create Chat Room Request Body

| Field | Type | Validation (Server) |
|-------|------|-------------------|
| `name` | `string` | Not empty, max 200 characters |
| `memberIds` | `int[]` | At least one member required |

---

## API Endpoints

All endpoints require `[Authorize]`. Base path: `/api/v1/chat`.

### Direct Messages

| Method | Path | Request | Response | Notes |
|--------|------|---------|----------|-------|
| GET | `/conversations` | -- | `ChatConversationResponseModel[]` | All DM conversations for the authenticated user, ordered by most recent |
| GET | `/messages/{otherUserId}` | `?page=1&pageSize=50` | `ChatMessageResponseModel[]` | Paginated message history. Auto-marks unread messages from `otherUserId` as read. Ordered ascending (newest last). |
| POST | `/messages` | `{ recipientId, content }` | `ChatMessageResponseModel` | Sends a DM. Returns 201 with Location header. Broadcasts `messageReceived` to recipient via SignalR. |
| POST | `/messages/{otherUserId}/read` | -- | 204 No Content | Marks all unread messages from `otherUserId` as read |

### Group Rooms

| Method | Path | Request | Response | Notes |
|--------|------|---------|----------|-------|
| GET | `/rooms` | -- | `ChatRoomResponseModel[]` | All rooms the authenticated user is a member of |
| POST | `/rooms` | `{ name, memberIds }` | `ChatRoomResponseModel` | Creates a group room. Creator is auto-added as member. Returns 201. |
| GET | `/rooms/{roomId}/messages` | `?page=1&pageSize=50` | `ChatMessageResponseModel[]` | Paginated room message history |
| POST | `/rooms/{roomId}/messages` | `{ content, recipientId: 0 }` | `ChatMessageResponseModel` | Sends a message to the room. Returns 201. |
| POST | `/rooms/{roomId}/members/{userId}` | -- | 204 No Content | Adds a user to the room |
| DELETE | `/rooms/{roomId}/members/{userId}` | -- | 204 No Content | Removes a user from the room |

### Response Models

**ChatConversationResponseModel:**

| Field | Type | Notes |
|-------|------|-------|
| `userId` | `int` | The other user's ID |
| `userName` | `string` | Full name (`FirstName LastName`) |
| `userInitials` | `string` | 2-character initials |
| `userColor` | `string` | Hex color for avatar |
| `lastMessage` | `string?` | Content of the most recent message |
| `lastMessageAt` | `DateTimeOffset?` | Timestamp of the most recent message |
| `unreadCount` | `int` | Count of unread messages from this user |

**ChatMessageResponseModel:**

| Field | Type | Notes |
|-------|------|-------|
| `id` | `int` | Message ID |
| `senderId` | `int` | Sender user ID |
| `senderName` | `string` | Sender full name |
| `senderInitials` | `string` | Sender initials |
| `senderColor` | `string` | Sender avatar color |
| `recipientId` | `int` | Recipient user ID |
| `content` | `string` | Message text |
| `isRead` | `bool` | Whether the recipient has read the message |
| `createdAt` | `DateTimeOffset` | UTC timestamp |

**ChatMessageEvent (SignalR):**

| Field | Type | Notes |
|-------|------|-------|
| `id` | `int` | Message ID |
| `senderId` | `int` | Sender user ID |
| `senderName` | `string` | Sender full name |
| `senderInitials` | `string` | Sender initials |
| `senderColor` | `string` | Sender avatar color |
| `recipientId` | `int` | Recipient user ID |
| `content` | `string` | Message text |
| `createdAt` | `DateTimeOffset` | UTC timestamp |

---

## Database Entities

### ChatMessage

Extends `BaseAuditableEntity`. Table: `chat_messages`.

| Column | Type | Notes |
|--------|------|-------|
| `sender_id` | `int` | FK to `users` |
| `recipient_id` | `int` | FK to `users` |
| `content` | `text` | Message body, max 4000 chars (validated) |
| `is_read` | `bool` | Default false |
| `read_at` | `timestamptz?` | Set when marked as read |
| `chat_room_id` | `int?` | FK to `chat_rooms` (null for DMs) |
| `file_attachment_id` | `int?` | FK to `file_attachments` |
| `linked_entity_type` | `text?` | Entity type for shared entities |
| `linked_entity_id` | `int?` | Entity ID for shared entities |

### ChatRoom

Extends `BaseAuditableEntity`. Table: `chat_rooms`.

| Column | Type | Notes |
|--------|------|-------|
| `name` | `text` | Room display name, max 200 chars |
| `is_group` | `bool` | True for group rooms |
| `created_by_id` | `int` | FK to `users` |

### ChatRoomMember

Extends `BaseAuditableEntity`. Table: `chat_room_members`.

| Column | Type | Notes |
|--------|------|-------|
| `chat_room_id` | `int` | FK to `chat_rooms` |
| `user_id` | `int` | FK to `users` |
| `joined_at` | `timestamptz` | When the member was added |

---

## Message History and Pagination

Messages are fetched using offset-based pagination:

| Parameter | Default | Notes |
|-----------|---------|-------|
| `page` | 1 | 1-indexed page number |
| `pageSize` | 50 | Messages per page |

Messages are ordered by `CreatedAt DESC` on the server (newest first for pagination), then reversed client-side so the most recent message appears at the bottom. The UI currently loads only the first page (most recent 50 messages) and does not implement scroll-to-load-more.

When messages are fetched, all unread messages from the other user are automatically marked as read in the same handler (batch `ExecuteUpdateAsync` setting `IsRead = true` and `ReadAt = UtcNow`).

---

## Known Limitations

1. **No group room UI** -- The backend fully supports group chat rooms (create, list, send messages, add/remove members), but the frontend only renders 1:1 DM conversations. The `ChatService` methods for rooms are implemented but unused by the component.

2. **No file/entity sharing UI** -- The `ChatMessage` entity supports file attachments and entity links, and the frontend model includes these fields, but the UI does not render or provide upload functionality for them.

3. **No typing indicators** -- The `ChatHub` does not broadcast typing events, and the UI does not display typing indicators.

4. **No infinite scroll** -- Only the first page of messages (50) is loaded. Older messages are not accessible via scroll-to-load.

5. **No message editing or deletion** -- Messages are immutable once sent. There is no edit or delete functionality.

6. **No read receipts in UI** -- The `isRead` field is tracked in the database and used to compute `unreadCount`, but individual message read status is not visually indicated in the message bubbles.

7. **No search within conversations** -- There is no search functionality for finding messages within a conversation.

8. **No presence/online status** -- The system does not track or display whether users are currently online.

9. **Panel-based only** -- Chat is a slide-out panel, not a full-page experience. The `/chat` route exists for lazy loading but the feature is designed as an overlay.

10. **Subscription leak risk** -- The `userSearchControl.valueChanges` subscription in `openUserPicker()` is created on each open without cleanup. Each invocation adds a new subscription.

11. **No push notifications** -- Real-time delivery only works when the chat panel is open and the SignalR connection is active. No browser push notifications are sent for missed messages.
