# Concertopia NFT Minting Setup Guide

To mint your generated pixel avatars as NFTs without making users download crypto wallets, we are using **Crossmint** (Approach A). Crossmint allows you to mint NFTs via a simple REST API and automatically creates hidden "custodial wallets" for your users based solely on their email addresses.

Follow these steps to get your API keys and connect them to Godot.

## Step 1: Create a Crossmint Developer Account
1. Go to the **[Crossmint Staging Console](https://staging.crossmint.com/console)**. 
   *(We use Staging first so you don't spend real money while testing. It uses the "Polygon Amoy" test network).*
2. Create an account and log in.

## Step 2: Get Your API Keys
1. In the Crossmint console, navigate to the **Developers** tab (or API Keys section).
2. Create a new Server-side API Key with **"Minting"** permissions.
3. You will receive two crucial pieces of information:
   - **Project ID** (`X-PROJECT-ID`)
   - **Client Secret** (`X-CLIENT-SECRET`)
4. **Copy these down!** You will need to paste them into the top of the `avatar_generation.gd` script.

## Step 3: Create an NFT Collection
Before you can mint an NFT, you need a "Collection" (a smart contract) to put them in.
1. In the Crossmint Staging Console, navigate to **Minting API > Collections**.
2. Click **Create Collection**.
3. Fill in the details:
   - **Name:** Concertopia Avatars
   - **Description:** Official pixel art avatars for the Concertopia universe.
   - **Blockchain:** Polygon (Amoy Testnet)
4. Once created, you will get a **Collection ID** (it looks like a long UUID string). 
5. **Copy this down!** You will need it for the script.

## Step 4: Configure the Godot Script
1. Open the Godot project and go to `scripts/avatar_generation.gd`.
2. Look at the very top of the script under the `# ── Crossmint NFT Configuration ──` section.
3. Replace the placeholder text with your actual keys from Steps 2 and 3:

```gdscript
const CROSSMINT_PROJECT_ID   : String = "YOUR_PROJECT_ID_HERE"
const CROSSMINT_CLIENT_SECRET: String = "YOUR_CLIENT_SECRET_HERE"
const CROSSMINT_COLLECTION_ID: String = "YOUR_COLLECTION_ID_HERE"
```

## Step 5: Test the Minting
1. Run your Godot project and navigate to the Avatar Generation screen.
2. Enter a prompt and hit **Generate**.
3. Once the avatar is created, the **"MINT NFT"** button will appear.
4. Click **Mint NFT**.
5. The Godot console and UI should report success! 

*Note: Because Crossmint mints to the email address tied to the user's Supabase account, they will automatically receive an email from Crossmint telling them they received an NFT and providing a link to view their new wallet!*

## Going to Production (Mainnet)
When you are ready to launch your real game and use real crypto:
1. Create an account at `www.crossmint.com` (the production site, not staging).
2. Add a credit card to fund the gas fees (it usually costs a few cents per mint on Polygon).
3. Create a production API Key and a new Production Collection.
4. Update the keys in `avatar_generation.gd` and change the `CROSSMINT_BASE_URL` from `https://staging.crossmint.com` to `https://www.crossmint.com`.