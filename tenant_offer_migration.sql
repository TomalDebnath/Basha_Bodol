-- Run this once in phpMyAdmin on the basha_bodol database.
-- Existing bookings are marked as already accepted so their current workflow remains usable.
ALTER TABLE bookings
  ADD COLUMN offer_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER status,
  ADD COLUMN offer_status ENUM('Pending','Accepted','Rejected') NOT NULL DEFAULT 'Pending' AFTER offer_amount;

UPDATE bookings
SET offer_status = 'Accepted'
WHERE status IN ('Accepted', 'In Progress', 'Completed');

-- Legacy Requested bookings remain Pending with a zero offer; the provider can
-- accept or reject them from the same dashboard controls.
