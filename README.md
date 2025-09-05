# Real-World-Schema
## 1) Stats for measurements table (Insertion + Migration)
__Stats for table with 1M records__ <br/>
![stats for measurements table with 1M rows](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/stats%20for%20measurements_1M.png)

__Stats for table with 10M records__ <br/>
![stats for measurements table with 10M rows](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/stats%20for%20measurements_10M.png)

__Stats for table with 100M records__ <br/>
![stats for measurements table with 100M rows](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/stats%20for%20measurements_100M.png)

## 2) Backing up and restoring DB before and after migration
![Backing up and restoring DB before and after migration](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/Backup%20and%20restore%20measurements.png)
## 3) Using expand-contract pattern to deprecate feet column
1) Backup the table
2) Add a new col total_inches
3) Update the queries to use both the columns
   - insert/ update to insert/update both the columns
   - select to use old_col data iff total_inches is null/ empty
4) Upadate the total_inches in batches until no row contains null for it
5) Remove the old_col(s)
# Simulating LinkedIn reactions journey...
## 4) Creating users, posts and likes schema
__Query to create users table__
```
create table users(
    id serial primary key,
    name text not null,
    email text not null unique,
    created_at timestamptz default now()
);
```
__Query to create posts table__
```
create table posts(
    id serial primary key,
    content text not null,
    user_id int not null references users(id),
    created_at timestamptz default now()
);
```
__Query to create likes table__
```
create table likes(
    id serial primary key,
    post_id int not null references posts(id),
    user_id int not null references users(id),
    created_at timestamptz default now()
);
```
## 5) Inserting dummy data to the tables
__Query to insert dummy data in users table__
```
insert into users(name, email) values
('Alice', 'alice@example.com'),
('Bob', 'bob@example.com'),
('Charlie', 'charlie@example.com');
```
![uses table](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/users%20table.png)
__Query to insert dummy data in posts table__
```
insert into posts(content, user_id) values
('Hello, world!', 1),
('My second post', 1),
('Another post by Bob', 2);
```
![posts table](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/posts%20table.png)
__Query to insert dummy data in likes table__
```
insert into likes(post_id, user_id) values
(1, 2),
(1, 3),
(2, 3);
```
![likes table](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/likes%20table.png)
## 6) Implementing reactions v1
![Reactions for v1](https://media.licdn.com/dms/image/v2/D4D08AQHMXC527Se7_g/croft-frontend-shrinkToFit1024/croft-frontend-shrinkToFit1024/0/1696290921316?e=2147483647&v=beta&t=zEzmiMzHaJiauRU2nrqnOArb83sUw5Px-U5wlH425uM)
1) take a backup of the existing table
   ```
   \! pg_dump -U postgres -d "real world schemas" -t likes -F c -f "C:\Users\HimanshuSingh\Downloads\Vyson\Real World Schemas\likes_table_backup.backup"
   ```
2) change table name to reactions
   ```
   alter table likes rename to reactions;
   ```
3) create enum having required reactions
   ```
   create type reaction_types_enum as enum('like', 'celebrate', 'love', 'insightful', 'curious');
   ```
4) add reaction_type column
   ```
   alter table reactions add column reaction_type reaction_types_enum default 'like';
   ```
5) confirm the changes
   ```
   select * from reactions;
   ```
   ```
   \d reactions
   ```
__Queries execution snapshot__
![v1 migration ✅](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/reactions%20table%20with%20initial%20reactions%20%5BQ6%5D.png)
## 7) Implemeting reactions v1.1 (using migration - no new table creation)
![Reactions for v1.1](https://swap.notion.site/image/https%3A%2F%2Fprod-files-secure.s3.us-west-2.amazonaws.com%2Fcd19b962-79c9-4d24-a16e-c848e0209452%2Fe5e6f64e-9c90-4f38-b991-a7551311e635%2Flinkedin_funny_reacion4.png?table=block&id=60da182d-eaa9-4bb4-a7fc-58e9e3eba524&spaceId=cd19b962-79c9-4d24-a16e-c848e0209452&width=1000&userId=&cache=v2)

since here we need two new enum values, we can add them to the already existing enum, as we can add enum values to enum but can't  delete or reaname existing enum values
1) add support and funny enum values at correct order
   ```
   alter type reaction_types_enum add value 'support' after 'celebrate';
   ```
   ```
   alter type reaction_types_enum add value 'funny' after 'support';
   ```
2) we don't need to backup before or after as we are just adding new values to enum, and no change is being done on the schema of the table

__Updated enum for reaction types__
![v1.1 migrated](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/reactions%20enum%20post%20covid%20%5BQ7%5D.png)
## 8) Implemeting reactions v1.2 (deprecating reaction - curious)
1) take a backup of the table as removing an enum value would impact records of table
2) create a new enum type catering new needs
   ```
   create type reaction_types_v1_2_enum as enum('like','celebrate','support','funny','love','insightful');
   ```
3) [Optional] Validate the new enum type
   ```
   SELECT * FROM pg_enum WHERE enumtypid = 'reaction_types_v1_2_enum'::regtype order by enumsortorder;
   ```
4) Change the reaction_type to 'like' at all places having it as 'curious'
   ```
   update reactions set reaction_type = 'like' where reaction_type = 'curious';
   ```
5) Alter the reaction_types column 
   - Drop the default value of column so that new data type can be assigned to column and won't get errors due to data integrity
   - Change data type to newly created enum type
   - type cast the existing reaction_types to text to newly created enum to cater to old data
   - set the new default from new enum
    ```
    alter table reactions
    alter column reaction_type drop default,
    alter column reaction_type type reaction_types_v1_2_enum 
    using reaction_type::text::reaction_types_v1_2_enum,
    alter column reaction_type set default 'like';
    ```
6) If the table has has 10M+ records, before step 4, we should create a new column of reaction_types_v1_2(reaction_types_v1_2_enum) and ensure that for all insert/update queries we update both the columns, and for select quries we check and use the old column value iff new column's value is null. Later, gradually we should update the new column, in batches to ensure the application is always up and running. Once no null/empty value is present in reaction_types_v1_2 we can set a default reaction_type, drop the old column and reanme the new column name.<br/>

__Pre migration details__
![snapshot before v1.2 migration](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/reactions%20table%20details%20before%20v1.2%20%5BQ8%5D.png)
__Migrated to v1.2 ✅__
![v1.2 migrated](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/reactions%20table%20details%20after%20implementing%20v1.2%20%5BQ8%5D.png)
## 9) Implemeting reactions v2 (In use)
> [!Note]
> As of Sept 2025 the reations being used are Like, Celebrate, Support, Love, Insightful, Funny
![Reactions for v2](https://media.licdn.com/dms/image/v2/D4D08AQGvH8viJRDLuA/croft-frontend-shrinkToFit1920/croft-frontend-shrinkToFit1920/0/1669619914332?e=1757656800&v=beta&t=c1JFjTInyWo8CwlETNmYt4tNUtTDHh1Zzgy76DhWzU4)

1) In this part there is just change in order of the enum values, so no need of backing up database/ tables
2) create a new enum type
   ```
   create type reaction_types_v2_enum as enum(
    'like', 'celebrate', 'support', 'love', 'insightful', 'funny');
   ```
3) alter the table [same as explained in 8.5]
    ```
    alter table reactions
    alter column reaction_type drop default,
    alter column reaction_type type reaction_types_v2_enum
    using reaction_type::text::reaction_types_v2_enum,
    alter column reaction_type set default 'like';
    ```
4) as explainned in 8.6 even here, if table has more than 10M+ records, will use expand-contract strategy
   - Backup the table
   - add a new column reaction_type_v2(reaction_types_v2_enum)
   - upadte the queries to use both the columns
       - insert/ update to insert/update both the columns
       - select to use old_col data iff reaction_type_v2 is null/ empty
   - upadate the reaction_type_v2 in batches until no row contains null for it
   - remove the old_col, rename reaction_type_v2<br/>

__Migrating and migrated to v2 ✅__
![v2 migration ✅](https://github.com/hs-4419/Real-World-Schema/blob/main/Images/reactions%20table%20details%20v2%20%5BQ9%5D.png)
# Observations
1) Why did I use enums? By using the data type for reactions as int, implementing v1.2 and v2 would have been so much simpler. If required to see the reaction name in sql, I could have created a table named reaction_types(id, type, priority). By adding priority I could have easily handled the updated versions with very less change and would have defeated the enum's in-built type where we can't drop it's value. What do you think?? 
