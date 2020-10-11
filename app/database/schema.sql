CREATE TABLE Users (
    id                  serial,
    username            text not null unique check (username ~ '^[A-Za-z0-9_-]{3,}$'),
    email               text not null unique,
    hashedPassword      text not null,
    PRIMARY KEY (id)
);

CREATE TABLE SearchQueries (
    userId              bigint not null,
    query               text not null,
    searchDate          timestamp not null,
    FOREIGN KEY (userId) references Users (id),
    PRIMARY KEY (userId, query, searchDate)
);

CREATE TABLE Categories (
    id                  serial,
    name                text unique not null,
    parentCategory      bigint,
    FOREIGN KEY (parentCategory) references Categories (id),
    PRIMARY KEY (id)
);
:x
CREATE TABLE Podcasts (
    id                  serial,
    rssFeed             text unique not null,
    title               text not null,
    author              text,
    description         text,
    thumbnail           text,
    PRIMARY KEY (id)
);

CREATE TABLE PodcastCategories (
    podcastId           bigint not null,
    categoryId          bigint not null,
    FOREIGN KEY (podcastId) references Podcasts,
    FOREIGN KEY (categoryId) references Categories,
    PRIMARY KEY (podcastId, categoryId)
);

CREATE TABLE Episodes (
    podcastId           bigint not null,
    sequence            integer check (sequence > 0),
    FOREIGN KEY (podcastId) references Podcasts (id),
    PRIMARY KEY (podcastId, sequence)
);

CREATE TABLE Listens (
    userId              bigint not null,
    podcastId           bigint not null,
    episodeSequence     integer,
    listenDate          timestamp not null,
    timestamp           integer not null,
    FOREIGN KEY (userId) references Users (id),
    FOREIGN KEY (podcastId, episodeSequence) references Episodes (podcastId, sequence),
    PRIMARY KEY (userId, podcastId, episodeSequence)
);

CREATE TABLE Subscriptions (
    userId              bigint not null,
    podcastId           bigint not null,
    FOREIGN KEY (userId) references Users (id),
    FOREIGN KEY (podcastId) references Podcasts (id),
    PRIMARY KEY (userId, podcastId)
);

CREATE TABLE PodcastRatings (
    userId              integer not null,
    podcastId           integer not null,
    rating              integer not null check (rating >= 1 and rating <= 5),
    FOREIGN KEY (userId) references Users (id),
    FOREIGN KEY (podcastId) references Podcasts (id),
    PRIMARY KEY (userId, podcastId)
);

CREATE TABLE EpisodeRatings (
    userId              bigint not null,
    podcastId           bigint not null,
    episodeSequence     integer not null,
    rating              integer not null check (rating >= 1 and rating <= 5),
    FOREIGN KEY (userId) references Users (id),
    FOREIGN KEY (podcastId, episodeSequence) references Episodes (podcastId, sequence),
    PRIMARY KEY (userId, podcastId, episodeSequence)
);

CREATE TABLE RejectedRecommendations (
    userId              bigint not null,
    podcastId           bigint not null,
    FOREIGN KEY (userId) references Users (id),
    FOREIGN KEY (podcastId) references Podcasts (id),
    PRIMARY KEY (userId, podcastId)
);



-- HELPER FUNCTIONS --


-- match_category_and_podcast helps for inserting into podcastCategories
create or replace function match_category_and_podcast(_podcast text, _category text)
returns table (podcastId bigint, categoryId bigint)
as $$
begin
    return query
    select sq.podcastId as podcastId, sq.categoryId as categoryId from (
        select Podcasts.id as podcastId, Categories.id as categoryId, categories.name
        from Categories
        join Podcasts on podcasts.title=_podcast
    ) as sq
    where name=_category;
end;
$$ language plpgsql;

-- match_category_and_parent helps for inserting into categories when a parent is required
create or replace function match_category_and_parent(_category text, _parent text)
returns table (id bigint, name text, parentCategory bigint)
as $$
begin
 return query
 select nextval(pg_get_serial_sequence('categories','id')) as id,
 sname as name, bar.id as parentCategory from (
  select * from categories
  inner join (
   select _category as sname, _parent as parentName
  ) as foo
  on parentName=categories.name
) as bar;
end;
$$ language plpgsql;