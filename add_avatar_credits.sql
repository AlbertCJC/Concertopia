-- Add avatar_credits column to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS avatar_credits INT4 DEFAULT 5;

-- Optional: If you want to ensure existing users get 5 credits, run this update
UPDATE public.profiles
SET avatar_credits = 5
WHERE avatar_credits IS NULL;
