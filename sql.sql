CREATE TABLE IF NOT EXISTS `warnings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(50) NOT NULL,
  `warn_count` int(11) NOT NULL DEFAULT 0,
  `last_reason` text NOT NULL,
  `last_admin_id` varchar(50) NOT NULL,
  `last_timestamp` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

ALTER TABLE users
ADD COLUMN `playtime` INT(11) DEFAULT 153,
ADD COLUMN `resolved_reports` INT(11) DEFAULT 0;

