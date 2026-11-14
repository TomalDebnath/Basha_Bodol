-- Optional hardening for the existing `basha_bodol` database. Review, then run once.

-- 1) One review per user per house (also enforced in code)
ALTER TABLE reviews ADD UNIQUE KEY uq_review_user_house (user_id, house_id);

-- 2) Helpful indexes for the new ownership-scoped queries
ALTER TABLE visits ADD INDEX idx_visits_house_status (house_id, status);
ALTER TABLE houses ADD INDEX idx_houses_owner (owner_id);

-- 3) Least-privilege application user (replace the password!). The app never needs DROP/ALTER/FILE.
-- CREATE USER 'bashabodol_app'@'localhost' IDENTIFIED BY 'a-long-random-password';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON basha_bodol.* TO 'bashabodol_app'@'localhost';
-- FLUSH PRIVILEGES;
