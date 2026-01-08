# Firestore Integration - Communities Feature

## Overview

The community forum feature now uses Firebase Firestore for persistent, real-time data storage and synchronization across all users.

## Updated Files

### 1. **community_forum_screen.dart**

Main screen displaying all communities with real-time Firestore data.

**Key Changes:**

- Replaced mock `_communities` list with `StreamBuilder` reading from Firestore
- `_addCommunity()` now writes to Firestore instead of local state
- Communities are sorted by creation date (newest first)
- Shows loading state while fetching data
- Displays empty state when no communities exist
- Added color constants: emerald, primaryBlue (removed unused coral, purple)

**Firestore Structure:**

```
communities/
├── {communityId}
    ├── name: string
    ├── description: string
    ├── creator: string (user UID)
    ├── creatorName: string
    ├── memberCount: number
    ├── members: array (user UIDs)
    ├── createdAt: timestamp
    └── posts/
        └── {postId}
            ├── author: string
            ├── authorId: string
            ├── content: string
            ├── timestamp: timestamp
            ├── likes: number
            ├── likedBy: array (user UIDs)
            └── commentCount: number
```

### 2. **community_detail_screen.dart**

Individual community view with real-time posts feed.

**Key Changes:**

- Constructor now accepts `communityId` instead of mock data
- Loads community info from Firestore with `StreamBuilder`
- Implements join functionality with Firestore updates
- Posts are stored in subcollection and loaded in real-time
- Like/unlike functionality with persistent storage
- Post creation writes to Firestore
- Shows join status check with loading indicator
- Users can only post if they've joined the community

**Features:**

- **Join Community**: Adds user UID to community's members array, increments memberCount
- **Create Posts**: Saves posts to `communities/{id}/posts` subcollection
- **Like Posts**: Tracks likes per post and user IDs in `likedBy` array
- **Real-time Updates**: All changes sync instantly across connected users
- **Timestamp Formatting**: Converts Firestore timestamps to readable format (e.g., "2h ago")

## Firestore Security Rules (Recommended)

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /communities/{communityId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.creator == request.auth.uid;
      allow update: if request.auth != null;
      allow delete: if request.auth != null && resource.data.creator == request.auth.uid;

      match /posts/{postId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null && request.resource.data.authorId == request.auth.uid;
        allow update: if request.auth != null && resource.data.authorId == request.auth.uid;
        allow delete: if request.auth != null && resource.data.authorId == request.auth.uid;
      }
    }
  }
}
```

## Color Scheme

- **Emerald**: `0xFF00D4A4` - Primary action color
- **Primary Blue**: `0xFF0066FF` - Secondary action color
- **Background**: `0xFFEFF3FF` - Light background
- **White**: Default for cards and containers

## User Experience Flow

1. **Viewing Communities**:

   - User opens Communities tab
   - Sees all communities from Firestore sorted by newest first
   - Can tap a community card to view details

2. **Creating a Community**:

   - User taps "New Community" button
   - Fills in name and description
   - Community is created in Firestore with user as creator
   - Added to the top of the list with "1 member" (the creator)

3. **Joining a Community**:

   - User opens community detail
   - Taps "Join" button
   - Added to community's members array
   - Member count increments
   - "Join" button changes to "Joined" and becomes disabled
   - Can now see and use the post input field

4. **Creating Posts**:

   - User types in "Share your thoughts..." field
   - Taps send button or hits Enter
   - Post is saved to Firestore with timestamp
   - Appears at top of posts list in real-time for all joined members

5. **Liking Posts**:
   - User taps heart icon on any post
   - Like is recorded in Firestore
   - Heart fills in red, like count increments
   - Tapping again removes the like

## Migration from Mock Data

All previous mock data has been completely replaced with Firestore queries:

- Communities list: Real-time query ordered by `createdAt`
- Community details: Real-time document listener
- Posts feed: Real-time subcollection query
- Member list: Stored as array in community document

## Error Handling

- Network errors display error messages to users
- Join failures show toast notifications
- Post creation failures show error feedback
- Graceful degradation for missing data

## Performance Optimizations

- StreamBuilder for efficient real-time updates
- Firebase offline persistence enabled by default
- Minimal re-builds using proper state management
- Timestamp-based sorting for consistent ordering

## Testing the Integration

1. **Create a Community**: User A creates "Morning Support" community
2. **Join Community**: User B searches and joins "Morning Support"
3. **Post Message**: User B posts "Started my morning routine"
4. **Like Post**: User A likes User B's post
5. **Real-time Sync**: Both users see updates immediately

## Next Steps (Potential Enhancements)

- [ ] Search/filter communities
- [ ] Community categories/tags
- [ ] Pin important posts
- [ ] Moderation tools
- [ ] User profiles linked to posts
- [ ] Reply/threading for posts
- [ ] Community badges/achievements
- [ ] Member role management (admin, moderator, member)
