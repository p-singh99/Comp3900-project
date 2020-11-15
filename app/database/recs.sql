create or replace function search(_query text)
returns table (subscribers bigint, title text, author text, description text, xml text, podcastid integer)
as $$
begin
    return query
    select count(s.podcastid), v.title, v.author, v.description, v.xml, v.id
    from searchvector v
    full outer join subscriptions s on s.podcastid=v.id
    where v.vector @@ plainto_tsquery(_query)
    group by (s.podcastid, v.title, v.author, v.description,v.xml, v.id, v.vector)
    order by ts_rank(v.vector, plainto_tsquery(_query)) desc;
end
$$ language plpgsql;


create or replace function recommendations(_userid integer)
returns table(title text, id integer, subscribers integer, eps text [])
as $$
declare
 i record;
 query text;
begin
create temp table subs (podcastid integer);
create temp table rejected (podcastid integer);
insert into subs select podcastid from subscriptions where userid=_userid;
insert into rejected select podcastid from rejectedrecommendations where userid=_userid;
for i in
    select p.title, p.id
	from podcasts p join listens l on p.id=l.podcastid
	where l.userid=_userid and p.id not in (select * from subs) and p.id not in (select * from rejected)
	order by l.listendate limit 20
loop
        title = i.title;
        id:= i.id;
        select count(*) into subscribers from subscriptions where podcastid=i.id;
        eps := array(select e.title from episodes e where podcastid=i.id limit 30);
        return next;
end loop;

-- search queries
for query in
    select searchqueries.query from searchqueries
    where userid=_userid
    order by searchdate desc limit 10
loop
    for i in
        select sq.subscribers, sq.podcastid, p.title from search(query) sq, podcasts p
        where sq.podcastid = p.id
        and sq.podcastid not in (select * from subs)
        and sq.podcastid not in (select * from rejected)
        limit 20
    loop
        title = i.title;
        id:= i.podcastid;
        subscribers:= i.subscribers;
        eps := array(select e.title from episodes e where podcastid=i.podcastid limit 30);
        return next;
    end loop;
end loop;

-- podcast categories
for i in
	select p.title, p.id, count(p.id)
	from podcasts p, podcastcategories pc, categories c
	where  p.id=pc.podcastid
	and pc.categoryid=c.id
	and c.id in
		(select distinct c.id
		from subs s, categories c, podcastcategories pc
		where s.podcastid=pc.podcastid and pc.categoryid=c.id)
	and p.id not in (select * from subs)
    and p.id not in (select * from rejected)
	group by p.title, p.id, p.xml order by count(p.id) desc limit 20
loop
    title = i.title;
	id:= i.id;
	select count(*) into subscribers from subscriptions where podcastid=i.id;
    eps := array(select e.title from episodes e where podcastid=i.id limit 30);
	return next;
end loop;
drop table subs;
drop table rejected;
end
$$ language plpgsql;
