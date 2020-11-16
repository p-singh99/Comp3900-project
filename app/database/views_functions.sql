-- counts the number of subscribers per podcast
create or replace view NumSubscribersPerPodcast as
select podcasts.id as podcastId, count(subscriptions.userId) as subscribers
from podcasts left outer join subscriptions
on subscriptions.podcastId = podcasts.id
group by podcasts.id
order by subscribers desc;

create or replace view podcastSubscribers as
select podcasts.xml, podcasts.id, count(subscriptions.podcastid)
from podcasts left outer join subscriptions on id=podcastid
group by podcasts.xml, podcasts.id, subscriptions.podcastid;

-- notifications details view
create or replace view notificationDetails as
select n.userId, n.podcastId, n.episodeGuid, e.title as episodeTitle, p.title as podcastTitle, n.id
from notifications n
join podcasts p on n.podcastId=p.id
join episodes e on n.episodeGuid=e.guid;

-- HELPER FUNCTIONS --

create or replace function subscribed_podcasts_for_user(_userId integer)
returns setof Podcasts
as $$
begin
    return query
    select podcasts.* from
    subscriptions join podcasts on subscriptions.podcastId = podcasts.id
    where subscriptions.userId = _userId;
end;
$$ language plpgsql;

create or replace function count_subscriptions_for_podcast(_podcastId integer)
returns table (subscribers bigint)
as $$
begin
    return query
    select NumSubscribersPerPodcast.subscribers
    from NumSubscribersPerPodcast
    where podcastId=_podcastId;
end;
$$ language plpgsql;

-- match_category_and_podcast helps for inserting into podcastCategories
create or replace function match_category_and_podcast(_podcast text, _category text)
returns table (podcastId integer, categoryId integer)
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
returns table (id integer, name text, parentCategory integer)
as $$
begin
 return query
 select cast(nextval(pg_get_serial_sequence('categories','id')) as integer) as id,
 sname as name, bar.id as parentCategory from (
  select * from categories
  inner join (
   select _category as sname, _parent as parentName
  ) as foo
  on parentName=categories.name
) as bar;
end;
$$ language plpgsql;


-- search vector view
create or replace view searchvector as
    select
    setweight(to_tsvector(title), 'A') ||
        setweight(to_tsvector(coalesce(author, '')), 'B') ||
        setweight(to_tsvector(coalesce(description)), 'C') as vector,
    podcasts.*
    from podcasts;


-- ratings view
create or replace view ratingsview as
    select id, coalesce(AVG(rating), 0) as rating FROM podcasts left outer join podcastratings on (podcastid = id) group by id;
