# Communities Feature - Visual & Functional Guide

## Screen 1: Communities List (community_forum_screen.dart)

### Layout:

```
┌─────────────────────────────────┐
│        Community           [⌘]  │ ← AppBar with emerald bg
├─────────────────────────────────┤
│                                 │
│    [Share. Support. Grow.]      │ ← Hero Card (blue→emerald gradient)
│                                 │
├─────────────────────────────────┤
│  🔍 Search communities...  [+]  │ ← Search + Create buttons
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │ 👥 Morning Accountability   ││ ← Community Card
│  │    128 members              ││
│  │                             ││
│  │ Daily check-ins and...      ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ 👥 Mindful Evenings         ││
│  │    86 members               ││
│  │ ... (scrollable list)       ││
│  └─────────────────────────────┘│
│                                 │
├─────────────────────────────────┤
│ [🏠] [👥] [📖] [👤]             │ ← Bottom nav (black pill)
└─────────────────────────────────┘
```

### Interactions:

1. **Tap Community Card** → Navigate to CommunityDetailScreen with communityId
2. **Tap [+] Button** → Show create community bottom sheet
3. **Create Community** → Write to Firestore, appears in list real-time
4. **Pull to Refresh** → StreamBuilder auto-updates

### Create Community Sheet:

```
┌─────────────────────────────────┐
│   Create a community            │
├─────────────────────────────────┤
│                                 │
│  [Community name        ]       │ ← TextField
│                                 │
│  [Description           ]       │ ← Multiline TextField
│  [                              │
│  ]                              │
│                                 │
│         [Create]                │ ← Emerald button
│                                 │
└─────────────────────────────────┘
```

### Real-Time Behavior:

```
User A: Creates "Morning Accountability"
↓ (instantly)
Firestore: communities/{id} created
↓ (StreamBuilder listening)
User A, B, C: See new community at top of list
↓
User B: Taps to view details
```

---

## Screen 2: Community Detail (community_detail_screen.dart)

### Layout When NOT Joined:

```
┌─────────────────────────────────┐
│  Morning Accountability [←]     │ ← AppBar
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │ 👥 Morning Accountability   ││ ← Header Card (gradient bg)
│  │    128 members • by Alex    ││
│  │                             ││
│  │ Daily check-ins...          ││
│  │                             ││
│  │ [  + Join  ] [ ↗ Share ]   ││
│  └─────────────────────────────┘│
│                                 │
│         Community Posts         │ ← Header
│                                 │
│  ┌─────────────────────────────┐│
│  │ 🔒 Join to see posts        ││ ← Empty state
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### Layout When JOINED:

```
┌─────────────────────────────────┐
│  Morning Accountability [←]     │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │ 👥 Morning Accountability   ││
│  │    128 members • by Alex    ││
│  │                             ││
│  │ Daily check-ins...          ││
│  │                             ││
│  │ [ ✓ Joined ] [ ↗ Share ]   ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ 👤 [Share your thoughts...] │→ │ ← Post input field
│  └─────────────────────────────┘│
│                                 │
│         Community Posts         │
│                                 │
│  ┌─────────────────────────────┐│
│  │ 👤 Alex M.      2 hours ago ││ ← Post Card
│  │                             ││
│  │ Just completed 30 days!     ││
│  │ Feeling stronger each day.. ││
│  │                             ││
│  │ ❤ 24  💬 3  ↗ 1             ││
│  └─────────────────────────────┘│
│                                 │
│  ┌─────────────────────────────┐│
│  │ 👤 Jordan K.    5 hours ago ││
│  │ ... (scrollable posts list) ││
│  └─────────────────────────────┘│
│                                 │
└─────────────────────────────────┘
```

### Colors in Detail Screen:

- **Header Card**: Blue (0xFF0066FF) → Emerald (0xFF00D4A4) gradient
- **Join Button**: White with emerald text
- **Joined Button**: Grey background, disabled state
- **Posts**: White cards with emerald icons
- **Like Heart**: Red when filled, grey outline when empty
- **Timestamps**: Grey text ("2h ago", "now")

### Interactions:

1. **Join Button (Not Joined)**

   ```
   Click → _joinCommunity()
   → Update Firestore: add user to members array
   → Increment memberCount
   → Change button to "Joined" (disabled)
   → Show post input field
   ```

2. **Create Post (Joined)**

   ```
   Type text → Click send/press Enter → _addPost()
   → Write to Firestore: communities/{id}/posts
   → Fields: author, authorId, content, timestamp, likes: 0, likedBy: []
   → Clear input field
   → Show success toast
   → Post appears at top of list in real-time
   ```

3. **Like Post**
   ```
   Click ❤️ → _toggleLike()
   → Check if user.uid in likedBy array
   → If not in array: increment likes, add user to likedBy
   → If in array: decrement likes, remove user from likedBy
   → Heart fills red / goes grey
   → Display haptic feedback
   ```

### Real-Time Sync Example:

```
User A: Posts "Day 30!"
├─ Firestore receives post
├─ StreamBuilder in User B's screen detects update
├─ User B sees new post appear instantly
└─ Both see same data

User B: Likes User A's post
├─ Firestore updates: likes: 1, likedBy: [B_uid]
├─ User A sees like count increase in real-time
└─ User B's heart turns red
```

---

## Data Flow Diagram

```
┌─────────────────┐
│   User Opens    │
│   Communities   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│  StreamBuilder queries          │
│  communities collection         │
│  orderBy('createdAt')           │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Display in ListView with        │
│  Community Cards               │
│  (emerald gradient background) │
└────────┬────────────────────────┘
         │
         ├─ User Taps Card
         │
         ▼
┌─────────────────────────────────┐
│  Navigate to DetailScreen       │
│  with communityId & name        │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Fetch join status              │
│  Check members array in         │
│  Firestore                      │
└────────┬────────────────────────┘
         │
         ├─ Not Joined
         │  ▼
         │  Show "Join" button
         │  Hide post input
         │
         └─ Joined
            ▼
            Show "Joined" button (disabled)
            Show post input field
            StreamBuilder posts collection

            ├─ User Creates Post
            │  ▼
            │  Write to Firestore
            │  Post appears in real-time
            │
            └─ User Likes Post
               ▼
               Update Firestore
               Heart turns red
               Like count increments
```

---

## Firestore Write Operations

### 1. Create Community

```
POST /communities
{
  "name": "Morning Accountability",
  "description": "Daily check-ins and encouragement",
  "creator": "userId123",
  "creatorName": "Alex",
  "memberCount": 1,
  "members": ["userId123"],
  "createdAt": FieldValue.serverTimestamp()
}
```

### 2. Join Community

```
UPDATE /communities/{id}
{
  "members": FieldValue.arrayUnion(["userId456"]),
  "memberCount": FieldValue.increment(1)
}
```

### 3. Create Post

```
POST /communities/{id}/posts
{
  "author": "Alex M.",
  "authorId": "userId123",
  "content": "Day 30 complete!",
  "timestamp": FieldValue.serverTimestamp(),
  "likes": 0,
  "likedBy": [],
  "commentCount": 0
}
```

### 4. Like Post

```
UPDATE /communities/{id}/posts/{postId}
{
  "likes": FieldValue.increment(1),
  "likedBy": FieldValue.arrayUnion(["userId456"])
}
```

---

## Error Scenarios & Recovery

| Scenario              | UI Response                      | Recovery          |
| --------------------- | -------------------------------- | ----------------- |
| Network error on join | "Error: Connection failed" toast | Retry join        |
| Post too long         | (Prevented by TextField limit)   | Show error        |
| Offline               | Posts show cached data           | Sync when online  |
| Failed like           | "Error updating post" toast      | Retry like        |
| User deleted          | Post author shows "Anonymous"    | Graceful handling |

---

## Performance Metrics

- **List Load**: < 1 second (cached communities)
- **Join**: < 500ms
- **Post Creation**: < 1 second
- **Like Toggle**: < 300ms
- **Real-time Sync**: < 2 seconds (network dependent)

---

## Success Indicators ✅

- [x] Communities persist across app restarts
- [x] New communities visible to all users instantly
- [x] Join status visible without page refresh
- [x] Posts appear in real-time for all members
- [x] Likes sync across all connected users
- [x] Member count updates in real-time
- [x] Timestamps format correctly
- [x] Error messages display properly
- [x] Color scheme matches brand
- [x] Navigation between screens smooth

This implementation brings the addiction recovery community feature to life with real, persistent, synchronized data across all HealTrack users.
