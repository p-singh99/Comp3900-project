CREATE TABLE Users (
	id 		integer,
	username	text not null unique check (username ~ '^[A-Za-z0-9_-]*$'),
	email 		text not null unique,
	hashedPassword 	text not null,
	PRIMARY KEY (id)
);

CREATE TABLE SearchQueries (
	userId 		integer,
	query 		text not null,
 	FOREIGN KEY (userId) references Users (id)
);

CREATE TABLE Categories (
	id		serial,
	name 		text,
	PRIMARY KEY (id)
);

CREATE TABLE Podcasts (
	id 		integer,
	rssFeed 	text not null,
	title		text not null,
	author		text,
	description	text,
	PRIMARY KEY (id)
);

CREATE TABLE PodcastCategories (
	podcastId 	integer,
	categoryId	integer,
	FOREIGN KEY (podcastId) references Podcasts,
	FOREIGN KEY (categoryId) references Categories,
	PRIMARY KEY (podcastId, categoryId)
);

CREATE TABLE Episodes (
	podcastId 	integer,
	sequence	integer check (sequence > 0),
	FOREIGN KEY (podcastId) references Podcasts (id),
	PRIMARY KEY (podcastId, sequence)
);

CREATE TABLE Listens (
	userId 		integer,
	podcastId	integer,
	episodeSequence	integer,
	listenDate	timestamp not null,
	timestamp	integer not null,
	FOREIGN KEY (userId) references Users (id),
	FOREIGN KEY (podcastId, episodeSequence) references Episodes (podcastId, sequence),
	PRIMARY KEY (userId, podcastId, episodeSequence)
);

CREATE TABLE Subscriptions (
	userId 		integer,
	podcastId	integer,
	FOREIGN KEY (userId) references Users (id),
	FOREIGN KEY (podcastId) references Podcasts (id),
	PRIMARY KEY (userId, podcastId)
);

CREATE TABLE PodcastRatings (
	userId 		integer,
	podcastId	integer,
	rating		integer not null check (rating >= 1 and rating <= 5),
	FOREIGN KEY (userId) references Users (id),
	FOREIGN KEY (podcastId) references Podcasts (id),
	PRIMARY KEY (userId, podcastId)
);

CREATE TABLE EpisodeRatings (
	userId 		integer,
	podcastId	integer,
	episodeSequence integer,
	rating		integer not null check (rating >= 1 and rating <= 5),
	FOREIGN KEY (userId) references Users (id),
	FOREIGN KEY (podcastId, episodeSequence) references Episodes (podcastId, sequence),
	PRIMARY KEY (userId, podcastId, episodeSequence)
);

CREATE TABLE RejectedRecommendations (
	userId		integer,
	podcastId	integer,
	FOREIGN KEY (userId) references Users (id),
	FOREIGN KEY (podcastId) references Podcasts (id),
	PRIMARY KEY (userId, podcastId)
);
