-- ============================================================
-- AUTOX MARKETPLACE - STORAGE BUCKETS
-- ============================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('product-images', 'product-images', TRUE,  10485760,
   ARRAY['image/jpeg','image/png','image/webp','image/gif']),
  ('avatars',        'avatars',        TRUE,   5242880,
   ARRAY['image/jpeg','image/png','image/webp']),
  ('shop-assets',    'shop-assets',    TRUE,  10485760,
   ARRAY['image/jpeg','image/png','image/webp']),
  ('kyc-documents',  'kyc-documents',  FALSE, 20971520,
   ARRAY['image/jpeg','image/png','application/pdf']),
  ('chat-images',    'chat-images',    FALSE, 10485760,
   ARRAY['image/jpeg','image/png','image/webp']),
  ('review-images',  'review-images',  TRUE,  10485760,
   ARRAY['image/jpeg','image/png','image/webp']);

-- Storage RLS policies
CREATE POLICY "product_images_public_read"
  ON storage.objects FOR SELECT USING (bucket_id = 'product-images');

CREATE POLICY "product_images_vendor_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'product-images' AND auth.role() = 'authenticated');

CREATE POLICY "avatars_public_read"
  ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "avatars_own_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1]);

CREATE POLICY "kyc_own_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'kyc-documents' AND auth.uid()::TEXT = (storage.foldername(name))[1]);

CREATE POLICY "kyc_own_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'kyc-documents' AND auth.uid()::TEXT = (storage.foldername(name))[1]);

CREATE POLICY "chat_images_participant_read"
  ON storage.objects FOR SELECT USING (bucket_id = 'chat-images' AND auth.role() = 'authenticated');

CREATE POLICY "chat_images_upload"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'chat-images' AND auth.role() = 'authenticated');
