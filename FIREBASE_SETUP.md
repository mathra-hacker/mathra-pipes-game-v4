# Online Leaderboard – Firebase setup (Firestore)

1. https://console.firebase.google.com -> **Add project** (e.g. `mathra-pipes-game`).
2. **Build -> Firestore Database -> Create database** (production mode, any region).
3. Firestore -> **Rules** -> paste this and **Publish**:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /players/{id} {
      allow read: if true;
      allow create, update: if request.resource.data.keys().hasOnly(
            ['name','score','levels','bestSeconds','updatedAt'])
          && request.resource.data.name is string
          && request.resource.data.name.size() <= 18
          && request.resource.data.score is int
          && request.resource.data.score < 1000000;
      allow delete: if false;
    }
  }
}
```

4. Project settings (gear icon) -> **General**:
   - **Project ID**  -> copy
   - **Web API Key** -> copy (shown under "Project settings"; if missing, add a Web app `</>` to the project)
5. Open `lib/data/services/firebase_config.dart` and paste both values into `projectId` and `apiKey`.
6. Rebuild the app.

## Where to see the players
Firebase console -> Firestore Database -> Data -> `players` collection.
Each document = one player (name, score, levels). The number of documents = number of players.
The app's Leaderboard -> Online tab also shows "👥 N players".
