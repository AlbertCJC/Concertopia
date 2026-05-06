# Implementation Plan: UI Polish & Feature Enhancements

## 1. UI/UX Polish (Consistency & Feel)
### 1.1 Audio Manager (Autoload)
- **Goal:** Provide audible feedback for user actions.
- **Action:** Create `scripts/audio_manager.gd`.
- **Sounds:** `hover`, `click`, `success`, `error`, `generation_start`.
- **Integration:** Call `AudioManager.play("click")` in button signals across all screens.

### 1.2 Loading Shimmers
- **Goal:** Visual feedback while waiting for AI image generation or profile fetches.
- **Action:** Implement a "Shimmer" overlay in `avatar_generation.gd`, `nft_generation.gd`, and `user_profile.gd`.
- **Effect:** A diagonal gradient tweening across the `TextureRect` until the `HTTPRequest` completes.

### 1.3 Responsive Layout Rigor
- **Goal:** Ensure UI scales perfectly across all aspect ratios.
- **Action:** Audit `nft_generation.gd` and `avatar_generation.gd`.
- **Changes:** Replace hardcoded `offset` values with `MarginContainer` constants and `VBox/HBox` alignment settings. Fix the `nft_badge` absolute positioning.

## 2. Feature Enhancements
### 2.1 The Vault (History Gallery)
- **Goal:** Allow users to view and reuse their past creations.
- **Data:** Add `avatar_history` (Array) and `nft_history` (Array) to `AuthManager.current_user`.
- **Persistence:** Update Supabase `profiles` table logic to include these fields.
- **Screen:** Create `screens/vault.tscn`.
    - Tabbed view: "Avatars" vs "NFTs".
    - Grid of `TextureRect` previews.
    - "Set as Active" button for avatars.
- **Navigation:** Add "VAULT" button to `home.gd` top bar.

### 2.2 Daily Login Rewards
- **Goal:** Increase user retention.
- **Logic:**
    - `AuthManager` tracks `last_login_reward_date`.
    - Upon login, compare current date with `last_login_reward_date`.
    - If new day: Grant 1 Credit and update `last_login_reward_date`.
- **UI:** Show a non-intrusive "Daily Reward Claimed: +1 Credit" toast/popup on the homepage.

---

## Technical Details

### AuthManager Profile Extension
The `update_user_details` function will be expanded to handle:
- `avatar_history`: `[]`
- `nft_history`: `[]`
- `last_reward_date`: `"YYYY-MM-DD"`

### AudioManager Interface
```gdscript
# AudioManager.gd
func play_sfx(sfx_name: String) -> void:
    # Logic to load and play from res://audio/sfx/
```

### Vault Data Structure
- `nft_history` entry: `{ "url": "...", "minted": bool, "timestamp": 1234567 }`
