#!/bin/bash

flutter run -d linux \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000 \
  --dart-define=SUPABASE_URL=https://ttnpswfqqrbnyflvwcqy.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_VsbtNBOBUxVyDuGHOtX3fw_fj7wjRNT
