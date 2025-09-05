-- Active: 1755868862763@@127.0.0.1@5432@real world schemas
create database "real world schemas";
\c "real world schemas";
use "real world schemas";

create table measurements_100M(
    id serial primary key,
    name text not null,
    feet int not null,
    inches int not null
);

select count(*) from measurements_100M;
select * from measurements_100M limit 100;

drop table measurements_10M;


--[Q2] Backup and restore DB at critical places
create table measurements(
    id serial primary key,
    name text not null,
    feet int not null,
    inches int not null
);

INSERT INTO measurements (name, feet, inches) VALUES
('Alice', 5, 7),
('Bob', 6, 2),
('Charlie', 5, 11);

-- Backup the database before changing the schema
-- pg_dump -U postgres -d your_database -F c -f backup_file.backup
\! pg_dump -U postgres -d "real world schemas" -F c -f "C:\Users\HimanshuSingh\Downloads\Vyson\Real World Schemas\real_world_schema_backup_before_changing_schema.backup"

ALTER TABLE measurements ADD COLUMN total_inches INT;
UPDATE measurements SET total_inches = (feet * 12) + inches;
SELECT * FROM measurements;
ALTER TABLE measurements DROP COLUMN feet, DROP COLUMN inches;

-- Backup the database after changing the schema
-- pg_dump -U postgres -d your_database -F c -f backup_file.backup
\! pg_dump -U postgres -d "real world schemas" -F c -f "C:\Users\HimanshuSingh\Downloads\Vyson\Real World Schemas\real_world_schema_backup_after_changing_schema.backup"

-- Restore the database before changing the schema
-- --clean ensures that the existing database is dropped before restoring the backup
-- --if-exists ensures that the restore operation does not fail if the database does not exist
\! pg_restore -U postgres -d "real world schemas" --clean --if-exists -F c "C:\Users\HimanshuSingh\Downloads\Vyson\Real World Schemas\real_world_schema_backup_before_changing_schema.backup"

-- Restore the database to the state after changing the schema
\! pg_restore -U postgres -d "real world schemas" --clean --if-exists -F c "C:\Users\HimanshuSingh\Downloads\Vyson\Real World Schemas\real_world_schema_backup_after_changing_schema.backup"

--[Q3] What's expand-contract pattern?

--[Q4] Creating users, posts, likes tables
create table users(
    id serial primary key,
    name text not null,
    email text not null unique,
    created_at timestamptz default now()
);

create table posts(
    id serial primary key,
    content text not null,
    user_id int not null references users(id),
    created_at timestamptz default now()
);

create table likes(
    id serial primary key,
    post_id int not null references posts(id),
    user_id int not null references users(id),
    created_at timestamptz default now()
);

--[Q5] Creating users, posts and likes table

insert into users(name, email) values
('Alice', 'alice@example.com'),
('Bob', 'bob@example.com'),
('Charlie', 'charlie@example.com');

insert into posts(content, user_id) values
('Hello, world!', 1),
('My second post', 1),
('Another post by Bob', 2);

insert into likes(post_id, user_id) values
(1, 2),
(1, 3),
(2, 3);

--[Q6] Introducing reaction in reactions table
-- create a backup of likes table before changing the schema
\! pg_dump -U postgres -d "real world schemas" -t likes -F c -f "C:\Users\HimanshuSingh\Downloads\Vyson\Real World Schemas\likes_table_backup.backup"

alter table likes rename to reactions;
create type reaction_types_enum as enum('like', 'celebrate', 'love', 'insightful', 'curious');
alter table reactions
add column reaction_types reaction_types_enum default 'like';
alter table reactions
rename column reaction_types to reaction_type;

--[Learning how to edit enums]
--[NOTE]: we can only add more enum values, 
--[Note]: we cannot remove or rename existing enum values
-- show enums
--SELECT * FROM pg_enum WHERE enumtypid = 'reaction_types_enum'::regtype;
-- using BEFORE and AFTER, by default if not mentioned, new value is added at the end
-- Add 'supportive' before 'curious'
-- ALTER TYPE reaction_types_enum ADD VALUE 'supportive' BEFORE 'curious';
-- Add 'dislike' after 'like'
-- ALTER TYPE reaction_types_enum ADD VALUE 'dislike' AFTER 'like';

--[Q7] Adding enum values
alter type reaction_types_enum add value 'support' after 'celebrate';
alter type reaction_types_enum add value 'funny' after 'support';

--[Q8] Dropping curious form enums reactions
select * from reactions;
insert into reactions(post_id, user_id, reaction_type) values(3, 2, 'curious');
create type reaction_types_v1_2_enum as enum('like', 'celebrate','support','funny','love', 'insightful');
SELECT * FROM pg_enum WHERE enumtypid = 'reaction_types_v1_2_enum'::regtype order by enumsortorder;
update reactions set reaction_type = 'like' where reaction_type = 'curious';
alter table reactions
alter column reaction_type drop default,
alter column reaction_type type reaction_types_v1_2_enum 
using reaction_type::text::reaction_types_v1_2_enum,
alter column reaction_type set default 'like';

--[Q9] Implementing reactions v2
create type reaction_types_v2_enum as enum(
    'like', 'celebrate', 'support', 'love', 'insightful', 'funny');
alter table reactions
alter column reaction_type drop default,
alter column reaction_type type reaction_types_v2_enum
using reaction_type::text::reaction_types_v2_enum,
alter column reaction_type set default 'like';

-- using expand-contract pattern
-- Expand phase
--1) create type reactions_types_v2_enum as enum('like', 'celebrate', 'support', 'love', 'insightful', 'funny');
--2) alter table reactions add column reaction_type_v2 reaction_types_v2_enum default 'like';

