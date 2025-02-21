CREATE TABLE codes (
    code VARCHAR(6) PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    type ENUM('tutor', 'student') NOT NULL,
    created_at DATETIME NOT NULL
);

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    type ENUM('tutor', 'student') NOT NULL,
    created_at DATETIME NOT NULL
);

