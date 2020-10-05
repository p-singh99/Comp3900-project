BEGIN TRANSACTION;

drop table PodcastCategories;
drop table Categories;
drop table EpisodeRatings;
drop table Listens;
drop table Episodes;
drop table PodcastRatings;
drop table Subscriptions;
drop table RejectedRecommendations;
drop table Podcasts;
drop table SearchQueries;
drop table Users;

select 'Now type "COMMIT" to confirm deletion or "ROLLBACK" to undo';
