-- Motibakery: reset and seed products from docs/Swiggy menu.txt
-- Run this after 003_create_products.sql

begin;

-- Clear existing products before reseeding.
truncate table public.products;

insert into public.products (
  handle,
  title,
  name,
  category,
  rate,
  weight,
  flavours,
  status,
  hs_code,
  option1_name,
  option1_value
)
values
  ('moti-toast', 'Moti Toast', 'Moti Toast', 'Bread Toast Products', '250gms:55 | 500gms:110', '250gms, 500gms', 2, 'active', '19054000', 'Weight', '250gms, 500gms'),
  ('kaju-toast', 'Kaju Toast', 'Kaju Toast', 'Bread Toast Products', '250gms:65 | 500gms:130', '250gms, 500gms', 2, 'active', '19054000', 'Weight', '250gms, 500gms'),
  ('jeera-toast', 'Jeera Toast', 'Jeera Toast', 'Bread Toast Products', '250gms:55 | 500gms:110', '250gms, 500gms', 2, 'active', '19054000', 'Weight', '250gms, 500gms'),
  ('rogni', 'Rogni', 'Rogni', 'Bread Toast Products', '250gms:50 | 500gms:100', '250gms, 500gms', 2, 'active', '19054000', 'Weight', '250gms, 500gms'),
  ('irani-toast', 'Irani Toast', 'Irani Toast', 'Bread Toast Products', '250gms:65', '250gms', 1, 'active', '19054000', 'Weight', '250gms'),
  ('surti-farmas-butter', 'Surti Farmas (Butter)', 'Surti Farmas (Butter)', 'Bread Toast Products', '250gms:71 | 500gms:142', '250gms, 500gms', 2, 'active', '19054000', 'Weight', '250gms, 500gms'),
  ('cake-rusk-300gms', 'Cake rusk 300gms', 'Cake rusk 300gms', 'Bread Toast Products', '1:209', '1', 1, 'active', '19059010', 'Weight', '1'),

  ('butter-jeera-khari', 'Butter Jeera Khari', 'Butter Jeera Khari', 'Khari', '500gms:146', '500gms', 1, 'active', '19054000', 'Weight', '500gms'),
  ('classic-khari', 'Classic Khari', 'Classic Khari', 'Khari', '500gms:126', '500gms', 1, 'active', '19054000', 'Weight', '500gms'),

  ('bread-1200-gms', 'Bread 1200 gms', 'Bread 1200 gms', 'Bread', '1:104', '1', 1, 'active', '19052000', 'Weight', '1'),
  ('bread-800-gms', 'Bread 800 gms', 'Bread 800 gms', 'Bread', '1:80', '1', 1, 'active', '19052000', 'Weight', '1'),
  ('bread-400-gms', 'Bread 400 gms', 'Bread 400 gms', 'Bread', '1:51', '1', 1, 'active', '19052000', 'Weight', '1'),

  ('mohanthal', 'Mohanthal', 'Mohanthal', 'Sweets', '250gms:178 | 500gms:356 | 1kg:712', '250gms, 500gms, 1kg', 3, 'active', '21069000', 'Weight', '250gms, 500gms, 1kg'),
  ('kaju-katli', 'Kaju Katli', 'Kaju Katli', 'Sweets', '250gms:285 | 500gms:570 | 1kg:1140', '250gms, 500gms, 1kg', 3, 'active', '21069000', 'Weight', '250gms, 500gms, 1kg'),
  ('anjeer-katli', 'Anjeer Katli', 'Anjeer Katli', 'Sweets', '250gms:295 | 500gms:590 | 1kg:1180', '250gms, 500gms, 1kg', 3, 'active', '21069000', 'Weight', '250gms, 500gms, 1kg'),
  ('khajur-bites', 'Khajur Bites', 'Khajur Bites', 'Sweets', '250gms:220 | 500gms:440 | 1kg:880', '250gms, 500gms, 1kg', 3, 'active', '21069000', 'Weight', '250gms, 500gms, 1kg'),
  ('assorted-bites-box-250gm', 'Assorted Bites Box 250gm', 'Assorted Bites Box 250gm', 'Sweets', '250gms:310', '250gms', 1, 'active', '21069000', 'Weight', '250gms'),
  ('gulab-jamun', 'Gulab Jamun', 'Gulab Jamun', 'Sweets', '6pcs:198', '6pcs', 1, 'active', '21069000', 'Weight', '6pcs'),
  ('rasgulla', 'Rasgulla', 'Rasgulla', 'Sweets', '6pcs:105', '6pcs', 1, 'active', '21069000', 'Weight', '6pcs'),
  ('rasmalai', 'Rasmalai', 'Rasmalai', 'Sweets', '5pcs:245', '5pcs', 1, 'active', '21069000', 'Weight', '5pcs'),
  ('soan-papdi', 'Soan Papdi', 'Soan Papdi', 'Sweets', '250gms:153 | 500gms:306', '250gms, 500gms', 2, 'active', '21069000', 'Weight', '250gms, 500gms'),

  ('kaju-makroom-200-gms', 'Kaju Makroom [200 gms]', 'Kaju Makroom [200 gms]', 'Cookies', '1:215', '1', 1, 'active', '19053211', 'Weight', '1'),
  ('almond-biscotti-300gms', 'Almond Biscotti [300gms]', 'Almond Biscotti [300gms]', 'Cookies', '1:215', '1', 1, 'active', '19053211', 'Weight', '1'),
  ('egg-biscuit', 'Egg Biscuit', 'Egg Biscuit', 'Cookies', '250gms:97', '250gms', 1, 'active', '19053211', 'Weight', '250gms'),
  ('premium-butter-kaju-cookies', 'Premium Butter Kaju Cookies', 'Premium Butter Kaju Cookies', 'Cookies', '500gms:370', '500gms', 1, 'active', '19053211', 'Weight', '500gms'),
  ('premium-butter-kesar-pista-cookies', 'Premium Butter Kesar Pista Cookies', 'Premium Butter Kesar Pista Cookies', 'Cookies', '500gms:370', '500gms', 1, 'active', '19053211', 'Weight', '500gms'),
  ('badam-coconut-cookies', 'Badam Coconut Cookies', 'Badam Coconut Cookies', 'Cookies', '250gms:93 | 500gms:186', '250gms, 500gms', 2, 'active', '19053211', 'Weight', '250gms, 500gms'),
  ('dark-chocolate', 'Dark Chocolate', 'Dark Chocolate', 'Cookies', '300gms:112 | 500gms:186', '300gms, 500gms', 2, 'active', '19053211', 'Weight', '300gms, 500gms'),
  ('tutti-prutti-cookies', 'Tutti Prutti Cookies', 'Tutti Prutti Cookies', 'Cookies', '300gms:112 | 500gms:186', '300gms, 500gms', 2, 'active', '19053211', 'Weight', '300gms, 500gms'),
  ('small-nankhatai', 'Small Nankhatai', 'Small Nankhatai', 'Cookies', '250gms:73 | 500gms:146', '250gms, 500gms', 2, 'active', '19053211', 'Weight', '250gms, 500gms'),
  ('salted', 'Salted', 'Salted', 'Cookies', '300gms:88 | 500gms:146', '300gms, 500gms', 2, 'active', '19053211', 'Weight', '300gms, 500gms'),
  ('special-assorted-cookies', 'Special Assorted cookies', 'Special Assorted cookies', 'Cookies', '500gms:146', '500gms', 1, 'active', '19053211', 'Weight', '500gms'),
  ('dry-fruits-assorted-cookies', 'Dry Fruits Assorted Cookies', 'Dry Fruits Assorted Cookies', 'Cookies', '500gms:186', '500gms', 1, 'active', '19053211', 'Weight', '500gms'),

  ('veg-puff', 'Veg Puff', 'Veg Puff', 'Savoury', '1pcs:30', '1pcs', 1, 'active', '19059030', 'Weight', '1pcs'),
  ('paneer-puff', 'Paneer Puff', 'Paneer Puff', 'Savoury', '1pcs:35', '1pcs', 1, 'active', '19059030', 'Weight', '1pcs'),
  ('aloo-matar-puff', 'Aloo Matar Puff', 'Aloo Matar Puff', 'Savoury', '1pcs:30', '1pcs', 1, 'active', '19059030', 'Weight', '1pcs'),
  ('paneer-chilly-roll', 'Paneer Chilly Roll', 'Paneer Chilly Roll', 'Savoury', '1pcs:50', '1pcs', 1, 'active', '19059030', 'Weight', '1pcs'),
  ('chicken-puff', 'Chicken Puff', 'Chicken Puff', 'Savoury', '1pcs:35', '1pcs', 1, 'active', '19059030', 'Weight', '1pcs'),
  ('butter-chicken-roll', 'Butter Chicken Roll', 'Butter Chicken Roll', 'Savoury', '1pcs:55', '1pcs', 1, 'active', '19059030', 'Weight', '1pcs'),
  ('chicken-burger', 'Chicken Burger', 'Chicken Burger', 'Savoury', '1pcs:50', '1pcs', 1, 'active', '19059030', 'Weight', '1pcs'),
  ('chicken-chilli-roll', 'Chicken Chilli Roll', 'Chicken Chilli Roll', 'Savoury', '1pcs:50', '1pcs', 1, 'active', '19059030', 'Weight', '1pcs'),

  ('eggless-pineapple-cake', 'Eggless Pineapple cake', 'Eggless Pineapple cake', 'Eggless cake', '500gms:300 | 1kg:600', '500gms, 1kg', 2, 'active', '19059010', 'Weight', '500gms, 1kg'),
  ('blackforest-cake', 'Blackforest Cake', 'Blackforest Cake', 'Eggless cake', '500gms:300 | 1kg:600', '500gms, 1kg', 2, 'active', '19059010', 'Weight', '500gms, 1kg'),
  ('chocolate-crunch-cake', 'Chocolate Crunch Cake', 'Chocolate Crunch Cake', 'Eggless cake', '500gms:360 | 1kg:720', '500gms, 1kg', 2, 'active', '19059010', 'Weight', '500gms, 1kg'),
  ('almond-honey-cake', 'Almond Honey cake', 'Almond Honey cake', 'Eggless cake', '500gms:325 | 1kg:720', '500gms, 1kg', 2, 'active', '19059010', 'Weight', '500gms, 1kg'),
  ('chocolate-dairy-milk-cake', 'Chocolate Dairy Milk cake', 'Chocolate Dairy Milk cake', 'Eggless cake', '500gms:490', '500gms', 1, 'active', '19059010', 'Weight', '500gms'),
  ('chocolate-truffle-cake', 'Chocolate Truffle Cake', 'Chocolate Truffle Cake', 'Eggless cake', '500gms:415 | 1kg:830', '500gms, 1kg', 2, 'active', '19059010', 'Weight', '500gms, 1kg');

commit;
