CREATE TABLE Users (
    id                  serial,
    username            text not null unique check (username ~ '^[a-z0-9_-]{3,}$'),
    email               text not null unique check (email ~ '^[a-z0-9+._-]+@[a-z0-9.-]+$'),   -- pretty close to the email spec, only doesn't allow for quote marks and backslashes
    hashedPassword      text not null,
    PRIMARY KEY (id)
);

CREATE TABLE SearchQueries (
    userId              integer not null,
    query               text not null,
    searchDate          timestamp not null,
    FOREIGN KEY (userId) references Users (id),
    PRIMARY KEY (userId, query, searchDate)
);

CREATE TABLE Categories (
    id                  serial,
    name                text unique not null check (lower(name) = name),
    parentCategory      integer,
    itunes              boolean not null,
    FOREIGN KEY (parentCategory) references Categories (id),
    PRIMARY KEY (id)
);

CREATE TABLE Podcasts (
    id                  serial,
    rssFeed             text unique not null,
    title               text not null,
    author              text,
    description         text,
    thumbnail           text,
    xml                 text,
    lastUpdated         timestamp,
    badXml              boolean,
    PRIMARY KEY (id)
);

CREATE TABLE PodcastCategories (
    podcastId           integer not null,
    categoryId          integer not null,
    FOREIGN KEY (podcastId) references Podcasts,
    FOREIGN KEY (categoryId) references Categories,
    PRIMARY KEY (podcastId, categoryId)
);

CREATE TABLE Episodes (
    podcastId           integer not null,
    guid                text not null,
    created             timestamp not null,
    title               text,
    pubDate             text,
    description         text,
    duration            text,
    FOREIGN KEY (podcastId) references Podcasts (id),
    PRIMARY KEY (podcastId, guid)
);

CREATE TABLE Listens (
    userId              integer not null,
    podcastId           integer not null,
    episodeGuid         text,
    listenDate          timestamp not null,
    timestamp           integer not null,
    complete            boolean,
    FOREIGN KEY (userId) references Users (id),
    FOREIGN KEY (podcastId, episodeGuid) references Episodes (podcastId, guid),
    PRIMARY KEY (userId, podcastId, episodeGuid)
);

CREATE TABLE Subscriptions (
    userId              integer not null,
    podcastId           integer not null,
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
    userId              integer not null,
    podcastId           integer not null,
    episodeGuid         text not null,
    rating              integer not null check (rating >= 1 and rating <= 5),
    FOREIGN KEY (userId) references Users (id),
    FOREIGN KEY (podcastId, episodeGuid) references Episodes (podcastId, guid),
    PRIMARY KEY (userId, podcastId, episodeGuid)
);

CREATE TABLE RejectedRecommendations (
    userId              integer not null,
    podcastId           integer not null,
    FOREIGN KEY (userId) references Users (id),
    FOREIGN KEY (podcastId) references Podcasts (id),
    PRIMARY KEY (userId, podcastId)
);

CREATE TYPE notificationStatus AS ENUM ('unread', 'read', 'dismissed');

CREATE TABLE Notifications (
    userId              integer not null,
    podcastId           integer not null,
    episodeGuid         text not null,
    id                  serial unique not null,
    status              notificationStatus not null,
    FOREIGN KEY (userId) references Users (id),
    FOREIGN KEY (podcastId, episodeGuid) references Episodes (podcastId, guid),
    PRIMARY KEY (userId, podcastId, episodeGuid)
);

