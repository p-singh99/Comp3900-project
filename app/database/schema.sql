CREATE TABLE Users (
	id 		integer,
	username	text not null unique check (username ~ '^[A-Za-z0-9_-]*$'),
	email 		text not null unique,
	hashedPassword 	text not null,
	salt		text not null,
	PRIMARY KEY (id)
);

CREATE TABLE SearchQueries (
	userId 		integer,
	query 		text not null,
 	FOREIGN KEY (userId) references Users (id)
);

CREATE TABLE Podcasts (
	id 		integer,
	rssFeed 	text not null,
	title		text not null,
	author		text,
	description	text,
	PRIMARY KEY (id)
);

CREATE TABLE Episodes (
	id 		integer,
	sequence	integer check (sequence > 0),
	PRIMARY KEY (id)
);

CREATE TABLE Listens (
	userId 		integer,
	episodeId	integer,
	listenDate	timestamp not null,
	timestamp	integer not null,
	FOREIGN KEY (userId) references Users (id),
	FOREIGN KEY (episoideId) references Episodes (id),
	PRIMARY KEY (userId, episodeId)
);
