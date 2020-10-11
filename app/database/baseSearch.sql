

CREATE OR REPLACE function
	searchFor(_searched text)
returns table(subscribers integer, title text, author text, description text)
as $$
declare _p Podcasts;
begin
    for _p in
	select p.title as title, p.author as author, p.description as description
	from   Podcasts p
	       full outer join Subscriptions s on (s.podcastid = p.id)
	where  to_tsvector(p.title || ' ' || p.author || ' ' || p.description) @@ plainto_tsquery(_searched)
	group by p.id
    loop
	if s.userid = NULL then
	    subscribers := 0;
	else
	    subscribers := _p.count(*);
        end if;
	
	return next;
    end loop;
end;
$$ language 'plpgsql';
