-- counts the number of subscribers per podcast
create or replace view NumSubscribersPerPodcast as
select podcasts.id as podcastId, count(subscriptions.userId) as subscribers
from podcasts left outer join subscriptions
on subscriptions.podcastId = podcasts.id
group by podcasts.id
order by subscribers desc;

-- counts number of podcasts which have each category
create or replace view NumPodcastsPerCategory as
select name, count(podcastCategories.podcastId) from podcastcategories
join categories on categories.id=podcastcategories.categoryid
group by name
order by count(podcastid) desc;

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
