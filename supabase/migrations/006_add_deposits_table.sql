-- AUTOX MARKETPLACE - MANUAL DEPOSITS TABLE
-- Replaces PayPal automatic top-up with manual bank deposit workflow

-- Create deposits table
CREATE TABLE IF NOT EXISTS deposits (
  id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                UUID    NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount                 INTEGER NOT NULL CHECK (amount > 0),
  reference_number       TEXT    NOT NULL,
  proof_url              TEXT    NOT NULL,
  status                 TEXT    NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
  reviewed_by            UUID REFERENCES profiles(id),
  rejection_reason       TEXT,
  wallet_balance_before  INTEGER NOT NULL DEFAULT 0,
  wallet_balance_after   INTEGER,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_deposits_user ON deposits(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_deposits_status ON deposits(status);

-- RLS
ALTER TABLE deposits ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "deposits_own_select" ON deposits;
DROP POLICY IF EXISTS "deposits_own_insert" ON deposits;
DROP POLICY IF EXISTS "deposits_admin" ON deposits;

CREATE POLICY "deposits_own_select" ON deposits
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "deposits_own_insert" ON deposits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "deposits_admin" ON deposits
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'moderator')
    )
  );

-- Remove PayPal settings, add bank info
DELETE FROM marketplace_settings WHERE key IN ('paypal_client_id', 'paypal_mode');

INSERT INTO marketplace_settings (key, value) VALUES
  ('bank_name',            '"Lead"'),
  ('bank_account_number',  '"212519935049"'),
  ('bank_routing_number',  '"101019644"'),
  ('bank_account_name',    '"Usher Miango Nkembenyi"'),
  ('deposit_instructions', '"Transfer the exact amount to the account above. Include your reference number in the transfer memo. Upload proof of payment to complete the deposit."')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW();