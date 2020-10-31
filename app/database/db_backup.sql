--
-- PostgreSQL database dump
--

-- Dumped from database version 12.4 (Ubuntu 12.4-1.pgdg18.04+1)
-- Dumped by pg_dump version 12.4 (Ubuntu 12.4-0ubuntu0.20.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: searchfor(text); Type: FUNCTION; Schema: public; Owner: brojogan
--

CREATE FUNCTION public.searchfor(_searched text) RETURNS TABLE(subscribers integer, title text, author text, description text)
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.searchfor(_searched text) OWNER TO brojogan;

--
-- Name: update_tsvector(); Type: FUNCTION; Schema: public; Owner: brojogan
--

CREATE FUNCTION public.update_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF NEW.id IS NULL THEN
            RAISE EXCEPTION 'id cannot be null';
        END IF;

        NEW.searchVector := setweight(to_tsvector(title),'A') ||
                            setweight(to_tsvector(coalesce(author,'')),'B') ||
                            setweight(to_tsvector(coalesce(description,'')),'C');
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.update_tsvector() OWNER TO brojogan;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    name text NOT NULL,
    parentcategory integer
);


ALTER TABLE public.categories OWNER TO brojogan;

--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: brojogan
--

CREATE SEQUENCE public.categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.categories_id_seq OWNER TO brojogan;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: brojogan
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: podcastcategories; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.podcastcategories (
    podcastid integer NOT NULL,
    categoryid integer NOT NULL
);


ALTER TABLE public.podcastcategories OWNER TO brojogan;

--
-- Name: categorycount; Type: VIEW; Schema: public; Owner: brojogan
--

CREATE VIEW public.categorycount AS
 SELECT categories.name,
    categories.id,
    count(podcastcategories.podcastid) AS count
   FROM (public.podcastcategories
     JOIN public.categories ON ((podcastcategories.categoryid = categories.id)))
  GROUP BY categories.name, categories.id
  ORDER BY (count(podcastcategories.podcastid)) DESC;


ALTER TABLE public.categorycount OWNER TO brojogan;

--
-- Name: episoderatings; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.episoderatings (
    userid integer NOT NULL,
    podcastid integer NOT NULL,
    episodeguid text NOT NULL,
    rating integer NOT NULL,
    CONSTRAINT episoderatings_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.episoderatings OWNER TO brojogan;

--
-- Name: episodes; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.episodes (
    podcastid integer NOT NULL,
    guid text NOT NULL
);


ALTER TABLE public.episodes OWNER TO brojogan;

--
-- Name: listens; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.listens (
    userid integer NOT NULL,
    podcastid integer NOT NULL,
    episodeguid text NOT NULL,
    listendate timestamp without time zone NOT NULL,
    "timestamp" integer NOT NULL
);


ALTER TABLE public.listens OWNER TO brojogan;

--
-- Name: podcastratings; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.podcastratings (
    userid integer NOT NULL,
    podcastid integer NOT NULL,
    rating integer NOT NULL,
    CONSTRAINT podcastratings_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.podcastratings OWNER TO brojogan;

--
-- Name: podcasts; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.podcasts (
    id integer NOT NULL,
    rssfeed text NOT NULL,
    title text NOT NULL,
    author text,
    description text,
    thumbnail text
);


ALTER TABLE public.podcasts OWNER TO brojogan;

--
-- Name: podcasts_id_seq; Type: SEQUENCE; Schema: public; Owner: brojogan
--

CREATE SEQUENCE public.podcasts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.podcasts_id_seq OWNER TO brojogan;

--
-- Name: podcasts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: brojogan
--

ALTER SEQUENCE public.podcasts_id_seq OWNED BY public.podcasts.id;


--
-- Name: rejectedrecommendations; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.rejectedrecommendations (
    userid integer NOT NULL,
    podcastid integer NOT NULL
);


ALTER TABLE public.rejectedrecommendations OWNER TO brojogan;

--
-- Name: searchqueries; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.searchqueries (
    userid integer NOT NULL,
    query text NOT NULL,
    searchdate timestamp without time zone NOT NULL
);


ALTER TABLE public.searchqueries OWNER TO brojogan;

--
-- Name: searchvector; Type: VIEW; Schema: public; Owner: brojogan
--

CREATE VIEW public.searchvector AS
 SELECT ((setweight(to_tsvector(podcasts.title), 'A'::"char") || setweight(to_tsvector(COALESCE(podcasts.author, ''::text)), 'B'::"char")) || setweight(to_tsvector(COALESCE(podcasts.description, ''::text)), 'C'::"char")) AS vector,
    podcasts.id,
    podcasts.rssfeed,
    podcasts.title,
    podcasts.author,
    podcasts.description,
    podcasts.thumbnail
   FROM public.podcasts;


ALTER TABLE public.searchvector OWNER TO brojogan;

--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.subscriptions (
    userid integer NOT NULL,
    podcastid integer NOT NULL
);


ALTER TABLE public.subscriptions OWNER TO brojogan;

--
-- Name: temp; Type: VIEW; Schema: public; Owner: brojogan
--

CREATE VIEW public.temp AS
 SELECT v.title AS query
   FROM (public.searchvector v
     FULL JOIN public.subscriptions s ON ((s.podcastid = v.id)))
  WHERE (v.vector @@ plainto_tsquery('something'::text))
  GROUP BY s.userid, v.title, v.author, v.description, v.id, v.vector
  ORDER BY (ts_rank(v.vector, plainto_tsquery('something'::text))) DESC;


ALTER TABLE public.temp OWNER TO brojogan;

--
-- Name: test; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.test (
    a integer,
    b text,
    c date
);


ALTER TABLE public.test OWNER TO brojogan;

--
-- Name: users; Type: TABLE; Schema: public; Owner: brojogan
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username text NOT NULL,
    email text NOT NULL,
    hashedpassword text NOT NULL,
    CONSTRAINT users_email_check CHECK ((email ~ '^[a-z0-9+._-]+@[a-z0-9.-]+$'::text)),
    CONSTRAINT users_username_check CHECK ((username ~ '^[a-z0-9_-]{3,}$'::text))
);


ALTER TABLE public.users OWNER TO brojogan;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: brojogan
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO brojogan;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: brojogan
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: podcasts id; Type: DEFAULT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.podcasts ALTER COLUMN id SET DEFAULT nextval('public.podcasts_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.categories (id, name, parentcategory) FROM stdin;
1	Education	\N
2	History	\N
3	News	\N
4	Arts	\N
5	Technology	\N
6	Society & Culture	\N
7	Design	4
8	Documentary	6
9	Comedy	\N
10	Sports & Recreation	\N
11	Religion & Spirituality	\N
12	Public Radio	\N
13	Music	\N
16	TV & Film	\N
17	News & Politics	\N
18	Games & Hobbies	\N
19	Talk Radio	\N
20	Health	\N
21	Arts & Entertainment	\N
22	Food	\N
23	Audio Blogs	\N
24	Science & Medicine	\N
25	Kids & Family	\N
26	Business	\N
27	Health & Fitness	\N
29	Society and culture	\N
30	comedy	\N
31	Sports	\N
32	Education & Training	\N
33	Video Games	\N
34	Science	\N
35	Leisure	\N
36	Movies & Television	\N
37	Government & Organizations	\N
44	Fiction	\N
45	Christianity	\N
46	Membership Matters	\N
47	Religion&	\N
48	Podcast	\N
67	Faithful	\N
68	Artist	\N
69	Non-Series Worship Services	\N
70	Sports &amp; Recreation	\N
71	Sports &amp; Cricket	\N
73	Natural Sciences	\N
74	教育	\N
77	cbcal	\N
78	church	\N
79	Religion & Spirituality:Christianity	\N
80	Education:K-12	\N
81	daft	\N
82	CBS	\N
83	CBS 라디오	\N
84	선교	\N
85	DJ	\N
86	nocutV	\N
87	뉴스	\N
88	CBS TV	\N
89	천주교 서울대교구 홍보위원회	\N
90	ReadyTalk	\N
91	Old Fashion Gospel Preaching	\N
92	australia	\N
93	cantonese	\N
94	bible	\N
95	awesome	\N
96	ccohs	\N
97	author	\N
98	cctn	\N
99	ccw	\N
100	Podcasting	\N
101	ar	\N
102	weight	\N
103	wine	\N
104	craic	\N
105	celtic	\N
106	battlecreek	\N
107	alchemy	\N
108	ableton	\N
109	music	\N
110	bef	\N
111	apostolic	\N
112	india	\N
113	chad	\N
114	books	\N
115	chance	\N
116	Science & Technology	\N
117	advice	\N
118	pop	\N
119	httpwwwrobertoknscomipodpodoindexhtml	\N
120	art	\N
121	baseball	\N
122	sha'ul	\N
123	christian	\N
124	1	\N
125	scifi	\N
126	chicago	\N
127	b96	\N
128	dutch	\N
129	chill-lounge-electronica	\N
130	china	\N
131	5g	\N
132	dance	\N
133	Technology:Podcasting	\N
134	anointing	\N
135	riverside	\N
136	py	\N
137	kansas	\N
138	comics	\N
139	Education:Language Courses	\N
140	house	\N
141	electro/	\N
142	chriss	\N
143	christ	\N
144	milton	\N
145	jazz	\N
146	action	\N
147	afternoon	\N
148	assembliesofgod	\N
149	podcast	\N
150	churchsoblessed	\N
151	genesis	\N
152	chynawhyte	\N
153	acting	\N
154	Arts:Food	\N
155	kyle	\N
156	cinema	\N
157	competitive	\N
158	Performing Arts	\N
159	fry	\N
160	citylife	\N
161	鉄道	\N
162	cj	\N
163	cjp	\N
164	science fiction	\N
165	clasicos	\N
166	soulful	\N
167	poetry	\N
168	adventure	\N
169	actions	\N
170	balance	\N
171	Truth	\N
172	customer	\N
173	burrows	\N
174	healthcare	\N
175	clint	\N
176	barker	\N
177	Games & Hobbies:Hobbies	\N
178	remediation	\N
179	alex	\N
180	david	\N
181	Chicago	\N
182	club	\N
183	mexico	\N
184	animation	\N
185	mentiras	\N
186	coaster	\N
187	coast fm	\N
188	コーヒーと牛乳	\N
189	Politics	\N
190	accion	\N
191	adobe	\N
192	colin	\N
193	blog	\N
194	8th	\N
195	biblioteque	\N
196	libary	\N
197	humor	\N
198	arts	\N
199	axis	\N
200	legal	\N
201	chris	\N
202	career	\N
203	adventuretime	\N
204	bestcomics	\N
205	vegas	\N
206	craft	\N
207	comedia	\N
208	cobh	\N
209	animals	\N
210	anarchism	\N
211	compositing	\N
212	it	\N
213	concertblast	\N
214	cine	\N
215	call	\N
216	videography	\N
217	da	\N
218	cittadinanza	\N
219	Nachrichten	\N
220	"180sec.tv"	\N
221	continue	\N
222	space	\N
223	alliance	\N
224	random	\N
225	Music:Music Interviews	\N
226	fr	\N
227	Environment, Science, Ocean	\N
228	Seattle	\N
229	garage	\N
230	spiritual	\N
231	科学，技術，コミュニケーション	\N
232	Games & Hobbies:Video Games	\N
233	nba	\N
234	Education:Self-Improvement	\N
235	Arizona Coyotes	\N
236	cheats	\N
237	cp	\N
238	housemusic	\N
239	alison	\N
240	audiobooks	\N
241	techno	\N
242	pastor	\N
243	cre8media	\N
244	cre8media ltd	\N
245	btcc	\N
246	CRE8MEDIA	\N
247	science	\N
248	Writing	\N
249	about	\N
250	edm	\N
251	cristo	\N
252	360	\N
253	クロスロード西宮，キリスト教，西宮，メッセージ，説教，crossroad	\N
254	New York City	\N
255	crookidcurtgrhm	\N
256	videogame	\N
257	calvarychapeloldtowne	\N
258	caribbean	\N
259	atlanta	\N
260	Sports & Recreation:Amateur	\N
261	kata	\N
262	dj	\N
263	csbs	\N
264	buddhism	\N
265	CSIS	\N
266	technology	\N
267	cs	\N
268	chin	\N
269	farm	\N
270	村田タケシ	\N
271	ann	\N
272	Games & Hobbies:Other Games	\N
273	movies	\N
274	duo	\N
275	NGO	\N
276	cuups	\N
277	creating	\N
278	avengers	\N
279	center	\N
280	electronic	\N
281	cy	\N
282	10k	\N
283	Society & Culture:Places & Travel	\N
284	dachief	\N
285	London	\N
286	athletes	\N
287	louis	\N
288	damagician78	\N
289	dameshek	\N
290	2012	\N
291	danceoneggshells	\N
292	dan	\N
293	horror	\N
294	cabri	\N
295	daniel	\N
296	shakira	\N
297	dannydx	\N
298	News & Current Events	\N
299	dansefarmradio	\N
300	videogames	\N
301	danyb	\N
302	prograssive	\N
303	darrenmain	\N
304	evangelical	\N
305	Higher Education	\N
306	datamax	\N
307	hop	\N
308	dave	\N
309	manly	\N
310	gay	\N
311	basscontrol	\N
312	bulldogs	\N
313	Pro Tools	\N
314	addiction	\N
315	Religion &amp; Spirituality	\N
316	hip	\N
317	dc	\N
318	washington	\N
319	ddt	\N
320	reggae	\N
321	deanjay	\N
322	agriculture	\N
323	freek	\N
324	mile	\N
325	kifinf	\N
326	axwell	\N
327	deep	\N
328	deephouse	\N
329	deepsound	\N
330	dek	\N
331	wtf	\N
332	delicious	\N
333	denali	\N
334	artist	\N
335	chemical	\N
336	Society & Culture:Personal Journals	\N
337	des	\N
338	Arizona Phoenix アリゾナ　アメリカ　天体観測　宇宙　astronomy music movie 音楽　映画	\N
339	design	\N
340	Religion	\N
341	crime	\N
342	detective	\N
343	media	\N
344	b.e.k.	\N
345	dfw116kb	\N
346	dgm	\N
347	games	\N
348	religion	\N
349	diabetes	\N
350	audio	\N
351	travel	\N
352	patricio	\N
353	diddorol	\N
354	magic	\N
355	philosophy	\N
356	NEWS	\N
357	digestive	\N
358	digibuzzmixtapes	\N
359	Entertainment	\N
360	Music:Music Commentary	\N
361	baltimore	\N
362	Технологии	\N
363	john ong	\N
364	dino	\N
365	atp	\N
366	dirtyboy	\N
367	sebastienjullien	\N
368	jackin	\N
369	breaks	\N
370	ηρωίνη	\N
371	History, Society, Culture, American History, Education, Museums, Collections	\N
372	disguistocast	\N
373	bollywood	\N
374	Disk House	\N
375	Family	\N
376	atheist	\N
377	districttrivia	\N
378	distrikt	\N
379	diva	\N
380	Outdoor	\N
381	bermuda	\N
382	divij	\N
383	disney	\N
384	djorge	\N
385	electro	\N
386	he	\N
387	hardcore	\N
388	rudimental	\N
389	bachata	\N
390	industrial	\N
391	#dj5ive	\N
392	dj811	\N
393	samui	\N
394	adrian	\N
395	djag	\N
396	al	\N
397	djandroid	\N
398	trancefamily	\N
399	San Diego	\N
400	chill	\N
401	benesia	\N
402	itunes	\N
403	ben	\N
404	above	\N
405	if	\N
406	banger	\N
407	hip-hop	\N
408	bishop	\N
409	top	\N
410	mixtape	\N
411	sub	\N
412	circuit	\N
413	give	\N
414	junior	\N
415	soca	\N
416	dubstep	\N
417	dancemusic	\N
418	craig	\N
419	crown	\N
420	16bit	\N
421	mix	\N
422	Музыка	\N
423	tiesto	\N
424	#housemusic	\N
425	dancehall	\N
426	louisville	\N
427	hiphop	\N
428	core	\N
429	beat	\N
430	hiphopmixes	\N
431	80's	\N
432	djduce	\N
433	dirty	\N
434	djeakut	\N
435	eddie	\N
436	salsa	\N
437	90s	\N
438	electrohouse	\N
439	trance	\N
440	cali	\N
441	jack	\N
442	tribal	\N
443	djjasonhilbert	\N
444	Anders	\N
445	the	\N
446	misionero	\N
447	gitri	\N
448	hacking	\N
449	paleo	\N
450	Todos	\N
451	spinboyz	\N
452	czech	\N
453	Levi	\N
454	killing time	\N
455	Geek	\N
456	boobjokes	\N
457	Environment	\N
458	foster	\N
459	WVMetroNews	\N
460	sailingboat	\N
461	audioguide	\N
462	drfritz	\N
463	sc1	\N
464	Mitochondrial disease	\N
465	education	\N
466	Automotive	\N
467	TWiT	\N
468	mac	\N
469	organize	\N
470	luis	\N
471	hawaii	\N
472	scrapbooking	\N
473	bassline	\N
474	organ	\N
475	vietnamese	\N
476	Chosen	\N
477	cannabis	\N
478	meneameland	\N
479	Lineberger	\N
480	FP技能士3級	\N
481	sports	\N
482	movie	\N
483	philosophy culture	\N
484	NAC	\N
485	American	\N
486	video	\N
487	Comedy:Comedy Interviews	\N
488	bikini	\N
489	bigbeats	\N
490	Science Magazine	\N
491	social media	\N
492	Entrepreneurship	\N
493	Literature	\N
494	Christian Life Church	\N
495	sermons	\N
496	Computers/Hacking	\N
497	revolta	\N
498	WMNF	\N
499	movies film tv television books podcast podcasts podcasting music new opinion married couple	\N
500	vegan	\N
501	Radio	\N
502	football	\N
503	tiempo	\N
504	Health & Fitness:Sexuality	\N
505	Other	\N
506	GRACE	\N
507	Pop	\N
508	comic	\N
509	Car	\N
510	iamdelfreaky	\N
511	International	\N
512	Sciences et médecine	\N
513	sermon	\N
514	Croc	\N
515	apple	\N
516	Techno	\N
517	MGCTv	\N
518	Julioso	\N
519	The	\N
520	new	\N
521	Prophecy	\N
522	null	\N
523	House	\N
524	coches	\N
525	Voice	\N
526	Christian	\N
527	NEWS & POLITICS	\N
528	wdrde default	\N
529	Television	\N
530	Avid	\N
531	Game	\N
532	Education/Higher Education	\N
533	sawbones	\N
534	Politics Progressive	\N
535	betting	\N
536	intel	\N
537	Jason	\N
538	soccer	\N
539	dr.	\N
540	alternate	\N
541	Louisiana	\N
542	poker	\N
543	brabazon	\N
544	Afro House	\N
545	Jonathan	\N
546	Drum & Bass	\N
547	EPIC	\N
548	Lutheran Sermons	\N
549	homebrewing	\N
550	google	\N
551	hp.com	\N
552	tech	\N
553	Sports & Recreation:Professional	\N
554	momotek	\N
555	community	\N
556	infinite	\N
557	Calvary	\N
558	Sioux	\N
559	signal	\N
560	learn	\N
561	Rosary	\N
562	Libertarian	\N
563	forerunner	\N
564	Brad	\N
565	bcat	\N
566	misjonskirken	\N
567	Religion y Espiritualidad	\N
568	village	\N
569	RZIM	\N
570	dating	\N
571	beyond	\N
572	Half Assed Morning Show rock sports minnesota	\N
573	streaming hela filmen	\N
574	12	\N
575	rowie	\N
576	CD	\N
577	Deep House	\N
578	goofy	\N
579	Lost	\N
580	radiosf	\N
581	NASCAR	\N
582	streams	\N
583	Kyle	\N
584	Lutheran	\N
585	business	\N
586	Moms and Family	\N
587	Horror	\N
588	southside	\N
589	Lifestyle	\N
590	english	\N
591	Society & Culture:Philosophy	\N
592	CoGe.oRg Podcast - Edizione italiana	\N
593	mcmillin	\N
594	gemz	\N
595	Comic	\N
596	short film director filmmaker anthony dalesandro colette bath nude suicide girls jamielyn sex lesbian comedy asian girl saki miata videotape voyeur dog story dina mande michelle featherstone film festival winner	\N
597	Politics Conservative	\N
598	neil	\N
599	gaming	\N
600	Rizzoli	\N
601	著者	\N
602	Morning	\N
603	Negativ	\N
604	idiots	\N
605	mod til ledelse	\N
606	california	\N
607	mobile	\N
608	anime	\N
609	Weblish	\N
610	wwe	\N
611	songs	\N
612	Hector	\N
613	PowerGamer	\N
614	digital	\N
615	Crossroads	\N
616	Travel	\N
617	norrtälje	\N
618	Nice	\N
619	Science Fiction	\N
620	emergency	\N
621	TV & Movies	\N
622	papa	\N
623	e	\N
624	Jobs	\N
625	Games & Hobbies:Automotive	\N
626	Wissenschaft und Medizin	\N
627	Sports News	\N
628	A	\N
629	host	\N
630	weekend worship services	\N
631	möllan.nu	\N
632	Sports:Tennis	\N
633	latvia	\N
634	lateral	\N
635	Lake	\N
636	Christian Bible Teaching	\N
637	Senior Portraits	\N
638	99	\N
639	among	\N
640	cpge	\N
641	Dlso	\N
642	Jewish	\N
643	paper	\N
644	Pets	\N
645	ndjt	\N
646	catholic	\N
647	Religion & Spirituality/Christianity	\N
648	NW	\N
649	Podbloggen	\N
650	band	\N
651	Film interviews	\N
652	New	\N
653	manga	\N
654	Visual Arts	\N
655	Welcome	\N
656	77027	\N
657	trinity	\N
658	Comunicação	\N
659	bangor	\N
660	equity	\N
661	film	\N
662	weather	\N
663	knitting	\N
664	Relationships	\N
665	Anime e Manga	\N
666	News, Politics, Religion, Spirituality	\N
667	Yo-Yo Ma	\N
668	fidget	\N
669	mash	\N
670	ambient	\N
671	Nauka	\N
672	Xbox	\N
673	musique	\N
674	Blue n Black Sound-Colours	\N
675	économie	\N
676	LAME	\N
677	Robinson	\N
678	photography	\N
679	recensioni	\N
680	acealvarez	\N
681	ABC	\N
682	mp3	\N
683	millionaire-interviews	\N
684	billy	\N
685	Boston Bruins	\N
686	Scrittura	\N
687	НТВ	\N
688	Kirche,Glaube,Verkündigungssendung	\N
689	Usama	\N
690	homily	\N
691	universo	\N
692	1370	\N
693	Health & Wellness	\N
694	breakbeat	\N
695	Books	\N
696	Disney	\N
697	Hobbies	\N
\.


--
-- Data for Name: episoderatings; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.episoderatings (userid, podcastid, episodeguid, rating) FROM stdin;
\.


--
-- Data for Name: episodes; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.episodes (podcastid, guid) FROM stdin;
1	52d66949e4b0a8cec3bcdd46:52d67282e4b0cca8969714fa:5e58de8a37459e0d069efda0
1	52d66949e4b0a8cec3bcdd46:52d67282e4b0cca8969714fa:5e29c894361f630aaf01c469
2	http://traffic.libsyn.com/dancarlinhh/dchha65_Supernova_in_the_East_IV.mp3
2	http://traffic.libsyn.com/dancarlinhh/dchha64_Supernova_in_the_East_III.mp3
3	tag:soundcloud,2010:tracks/905365285
3	tag:soundcloud,2010:tracks/901319959
4	prx_96_d0e54846-eb8f-486a-b10b-f6764469f028
4	prx_96_3657a2b6-10a1-4580-8cce-ca8aff53b177
5	c14e79d0-e2c3-11e9-be80-8b8c640993e8
5	2ae7f282-33ef-11ea-b18b-0f97aef9b5a6
6	http://podcasts.joerogan.net/?post_type=podcasts&p=10128
6	http://podcasts.joerogan.net/?post_type=podcasts&p=10124
1	test_data
2	test_data2
\.


--
-- Data for Name: listens; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.listens (userid, podcastid, episodeguid, listendate, "timestamp") FROM stdin;
25	1	test_data	2020-01-01 05:05:05	0
25	2	test_data2	2010-01-01 05:05:05	0
\.


--
-- Data for Name: podcastcategories; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.podcastcategories (podcastid, categoryid) FROM stdin;
1	1
2	2
3	3
4	4
4	7
5	5
5	6
5	8
38	4
39	9
37	12
44	11
38	6
40	13
46	6
47	9
39	16
38	16
39	17
39	6
39	18
49	19
54	1
55	20
55	11
56	18
57	16
57	4
57	5
58	13
60	13
61	13
62	16
60	21
62	5
63	19
64	9
65	21
66	5
67	4
69	19
68	22
67	18
71	6
69	12
67	16
69	23
72	24
72	6
73	11
73	1
75	25
76	16
77	16
78	13
79	18
81	13
80	26
79	4
116	13
117	9
118	13
119	11
121	6
122	6
124	9
127	11
129	5
130	9
131	13
132	13
134	25
135	9
128	27
138	25
122	17
124	6
140	9
127	6
141	16
129	17
142	13
130	16
132	16
134	4
128	1
144	6
138	4
145	1
147	1
140	6
141	13
148	27
149	21
129	13
151	13
130	5
132	4
146	29
134	16
153	5
154	5
138	16
150	30
147	6
152	31
140	4
141	1
145	32
157	11
155	33
153	16
148	34
158	13
154	17
160	23
147	17
140	25
159	35
154	16
160	13
154	6
160	36
177	9
177	17
177	1
188	4
189	10
189	16
190	35
191	24
192	26
193	17
191	11
192	5
191	1
194	10
195	4
196	35
196	6
197	26
199	6
200	6
201	6
202	6
203	6
204	6
205	6
207	4
208	6
209	6
210	13
211	9
212	13
213	11
199	37
207	9
208	37
214	13
209	37
210	1
211	6
199	1
207	10
208	1
209	1
210	4
211	17
215	3
217	11
221	4
221	44
225	4
226	18
227	4
228	10
228	6
229	13
229	23
230	9
231	4
232	26
229	5
233	16
242	26
247	6
248	17
249	34
250	25
251	6
252	6
253	34
254	6
255	3
256	34
257	6
258	3
259	17
260	17
261	6
262	9
263	17
264	11
265	3
266	6
268	17
269	6
270	6
271	6
272	44
273	34
237	45
274	9
275	6
281	6
284	6
285	3
241	46
290	6
291	6
292	25
293	11
294	6
295	3
296	9
297	6
298	6
299	6
300	6
302	9
303	26
304	6
305	6
306	3
307	11
245	47
308	3
309	6
310	13
311	6
312	6
313	6
314	6
315	6
318	3
319	3
320	3
321	13
322	9
323	6
324	6
326	6
327	6
328	6
330	6
331	6
332	34
333	3
334	25
335	3
336	3
337	6
338	3
339	3
340	3
341	3
342	31
343	6
344	13
345	3
346	6
347	26
349	6
350	34
351	6
352	3
354	31
355	11
356	6
357	6
358	11
359	3
360	6
361	34
362	13
363	9
364	3
365	3
366	6
367	3
368	6
369	6
370	6
371	6
372	6
373	3
374	3
375	3
376	6
378	9
379	11
380	3
381	34
382	3
383	6
384	27
385	11
386	34
387	9
388	3
389	34
390	11
391	6
393	6
394	6
395	11
396	26
397	34
267	48
398	34
399	26
401	3
402	11
403	6
405	9
406	5
407	5
408	5
409	5
410	1
411	16
412	5
413	1
415	21
416	13
417	11
418	5
419	21
420	3
421	16
422	16
423	34
424	13
425	11
426	11
427	6
428	17
429	16
430	21
431	6
432	10
433	4
434	3
435	13
436	9
384	6
405	11
241	67
416	6
421	4
422	4
423	1
424	4
426	37
427	35
430	36
418	68
384	3
405	6
421	18
422	18
423	26
426	4
427	13
430	13
241	69
418	16
439	13
441	11
442	24
442	17
444	11
445	70
446	70
445	71
447	11
448	5
448	4
449	18
450	5
451	11
452	11
453	20
456	9
455	73
457	26
456	16
458	21
459	13
456	24
458	13
460	6
461	18
458	5
462	35
463	10
469	18
471	5
472	25
471	4
472	10
471	24
473	74
472	16
474	9
475	9
475	6
475	4
476	13
536	30
539	11
540	11
541	77
544	78
546	79
547	80
549	81
551	79
554	82
556	83
557	84
558	85
559	3
560	17
561	83
562	86
563	86
564	86
565	82
566	86
567	86
568	87
569	17
570	88
572	89
573	89
574	89
575	89
576	4
578	90
580	91
583	11
587	11
588	92
589	93
590	94
591	95
595	96
596	97
598	98
599	99
602	1
605	13
608	16
609	100
610	5
614	18
615	5
616	35
618	5
633	101
635	11
643	102
645	103
647	104
648	105
653	106
658	107
659	108
660	11
662	11
663	11
667	109
672	110
675	111
676	17
677	11
678	11
682	112
683	113
686	114
687	115
688	116
689	116
692	6
693	5
694	5
695	5
700	5
701	5
702	5
703	5
704	5
705	5
706	5
707	5
708	5
709	5
710	5
711	5
712	5
713	5
714	5
715	5
716	5
717	5
734	117
735	118
739	119
751	120
753	121
754	122
755	37
756	37
757	37
760	31
762	123
764	124
765	11
770	125
771	9
773	126
774	127
778	17
779	128
781	1
782	129
784	130
785	131
788	1
789	132
790	133
791	13
792	134
793	6
795	11
796	13
797	135
800	136
801	11
803	137
805	138
806	9
807	13
808	11
810	13
811	139
812	16
813	27
814	140
815	141
817	140
818	31
819	142
820	6
823	11
824	45
825	45
827	11
829	143
831	11
833	79
834	144
835	11
838	145
839	146
840	26
842	11
843	11
844	4
845	11
849	147
850	30
854	94
855	11
856	148
860	11
861	11
864	11
865	149
868	150
869	11
871	151
872	152
873	153
874	1
875	154
878	11
882	155
887	16
888	16
889	156
890	16
892	16
893	1
894	157
895	158
896	10
899	108
901	159
904	160
905	114
907	37
908	37
909	4
911	37
912	37
913	37
914	37
915	37
916	37
917	37
918	37
919	37
920	37
922	26
923	31
925	1
926	4
927	161
930	162
931	163
932	4
935	13
936	45
939	164
941	165
942	13
944	166
945	167
947	168
948	169
949	170
951	171
952	1
953	11
955	11
958	172
961	100
962	13
963	9
964	173
966	9
968	174
969	175
970	26
971	31
973	176
974	11
975	177
980	132
983	178
984	179
985	180
987	181
988	13
989	13
991	182
993	182
999	183
1001	4
1005	184
1007	185
1010	26
1011	10
1014	186
1015	187
1016	13
1020	10
1021	6
1022	188
1023	189
1024	16
1026	11
1027	140
1029	190
1032	13
1034	9
1036	6
1037	191
1038	191
1039	191
1040	192
1041	193
1042	194
1043	195
1044	196
1046	11
1049	11
1052	197
1057	198
1059	11
1060	11
1061	11
1062	11
1063	11
1064	199
1065	200
1067	201
1070	202
1071	1
1072	201
1073	35
1074	4
1078	203
1081	4
1082	204
1084	4
1085	31
1088	5
1091	26
1092	35
1093	1
1095	11
1105	205
1107	206
1108	207
1109	208
1110	209
1112	210
1113	211
1114	211
1115	211
1117	5
1118	212
1119	9
1120	13
1121	213
1125	214
1127	13
1128	215
1136	216
1138	20
1144	217
1145	218
1178	1
1179	1
1180	1
1181	1
1182	1
1183	1
1184	1
1185	1
1186	1
1187	20
1191	219
1192	220
1193	79
1194	221
1196	13
1200	222
1202	223
1204	224
1205	78
1209	3
1210	149
1212	140
1214	225
1218	226
1219	13
1220	1
1222	227
1227	11
1228	45
1229	45
1230	45
1231	45
1232	45
1233	45
1235	11
1239	228
1247	229
1251	21
1252	9
1253	138
1254	9
1255	230
1256	11
1257	13
1258	231
1265	232
1271	145
1273	1
1274	30
1275	1
1276	233
1277	6
1281	234
1286	20
1289	1
1290	235
1291	235
1292	35
1293	236
1295	79
1296	1
1297	11
1298	237
1299	238
1301	6
1304	30
1305	4
1307	239
1308	240
1311	16
1312	241
1314	109
1315	9
1322	242
1323	243
1324	243
1325	244
1326	243
1327	10
1328	245
1329	246
1330	25
1331	10
1332	16
1334	26
1335	247
1337	248
1338	249
1341	250
1343	11
1345	9
1348	31
1353	251
1354	24
1355	95
1356	95
1357	252
1358	13
1360	253
1362	254
1364	255
1365	256
1366	257
1368	10
1372	11
1378	11
1382	1
1388	258
1392	259
1395	260
1396	30
1397	261
1398	262
1399	263
1400	264
1402	10
1403	181
1404	265
1405	11
1406	114
1407	1
1408	266
1409	191
1410	267
1412	268
1413	189
1416	269
1417	21
1419	270
1420	271
1422	272
1424	13
1427	13
1429	4
1430	9
1434	13
1437	273
1438	120
1446	274
1447	13
1448	13
1449	13
1451	275
1454	13
1458	276
1460	100
1461	277
1464	278
1467	279
1468	6
1470	280
1471	281
1472	282
1473	283
1477	1
1479	13
1487	13
1488	17
1489	17
1490	126
1491	284
1494	285
1497	25
1503	286
1504	9
1505	6
1508	11
1512	109
1517	287
1518	287
1519	288
1520	9
1521	289
1525	30
1528	290
1529	291
1531	25
1534	292
1535	5
1536	109
1537	293
1539	294
1540	295
1541	13
1542	296
1544	79
1547	13
1549	297
1551	298
1552	299
1553	16
1554	300
1555	301
1556	13
1558	302
1559	16
1561	13
1563	17
1564	10
1565	126
1566	13
1567	303
1569	304
1570	11
1571	305
1575	217
1577	11
1578	13
1579	5
1580	306
1581	4
1582	307
1584	140
1585	36
1586	140
1588	13
1589	10
1590	308
1592	30
1595	30
1596	309
1599	13
1600	9
1601	24
1602	24
1603	24
1606	310
1608	311
1609	312
1610	313
1611	314
1612	315
1615	13
1616	13
1617	262
1618	11
1620	316
1621	11
1623	5
1625	13
1630	10
1631	317
1634	318
1635	10
1636	13
1637	95
1638	16
1639	319
1640	26
1649	9
1653	320
1655	13
1656	30
1658	321
1662	241
1663	16
1664	168
1666	322
1668	11
1669	262
1673	262
1674	13
1675	13
1677	140
1678	323
1679	324
1680	325
1681	13
1682	262
1684	13
1685	140
1688	140
1690	326
1692	13
1694	327
1695	328
1697	13
1698	329
1701	11
1703	16
1704	330
1706	331
1707	1
1708	332
1709	6
1711	9
1713	6
1714	48
1716	333
1717	6
1719	26
1720	10
1721	30
1722	334
1724	11
1727	37
1729	1
1730	335
1731	20
1733	25
1735	13
1737	336
1738	337
1739	338
1741	5
1742	339
1743	4
1744	4
1746	13
1747	4
1749	24
1752	340
1753	341
1754	341
1755	342
1757	35
1758	3
1759	5
1763	343
1764	34
1765	5
1767	5
1768	344
1771	1
1772	345
1774	346
1775	1
1778	11
1779	347
1780	348
1781	117
1783	349
1784	350
1786	351
1787	109
1789	133
1790	352
1797	353
1802	11
1803	354
1804	355
1805	13
1806	356
1807	357
1808	358
1809	48
1810	24
1811	16
1812	140
1814	347
1816	359
1818	13
1819	11
1820	24
1822	360
1823	361
1824	9
1825	362
1826	363
1827	363
1828	363
1829	114
1830	364
1835	149
1838	365
1839	350
1840	366
1842	140
1843	367
1844	368
1845	9
1846	13
1847	369
1848	370
1850	1
1857	371
1858	168
1859	372
1860	373
1861	374
1872	375
1875	13
1876	376
1877	377
1878	378
1879	13
1881	379
1882	380
1883	380
1885	381
1887	382
1888	79
1889	11
1890	11
1891	11
1892	11
1893	11
1894	11
1895	327
1898	383
1900	384
1901	166
1902	13
1903	385
1904	13
1905	13
1906	13
1907	13
1908	13
1910	386
1911	13
1912	13
1913	13
1914	262
1915	13
1917	387
1918	13
1919	13
1920	13
1921	388
1922	310
1923	13
1924	13
1925	13
1926	389
1927	390
1929	13
1930	13
1931	13
1932	13
1933	262
1934	262
1936	13
1937	100
1939	140
1940	13
1941	391
1942	392
1943	140
1944	13
1945	140
1946	393
1947	394
1948	395
1949	140
1950	132
1951	140
1952	182
1953	396
1954	262
1955	132
1956	397
1957	13
1959	13
1960	13
1962	398
1963	140
1964	262
1965	262
1966	399
1967	140
1968	140
1969	262
1970	149
1971	400
1972	109
1974	13
1975	401
1976	402
1977	403
1978	404
1979	140
1980	405
1981	262
1982	406
1983	407
1985	408
1986	262
1988	409
1990	410
1991	262
1992	411
1993	13
1994	262
1995	412
1996	13
1997	316
1998	140
1999	13
2000	413
2001	13
2002	414
2003	13
2006	13
2007	415
2008	140
2009	416
2010	13
2011	262
2012	417
2013	262
2015	13
2016	262
2017	262
2018	418
2019	13
2020	262
2023	419
2024	262
2025	420
2026	334
2028	13
2029	421
2031	182
2032	422
2033	423
2035	424
2036	425
2037	426
2038	427
2040	149
2041	262
2042	428
2043	262
2045	132
2046	132
2047	429
2049	285
2050	262
2051	13
2052	430
2053	431
2054	320
2055	432
2056	433
2057	13
2058	434
2059	13
2060	262
2062	262
2063	435
2064	422
2065	13
2066	140
2067	13
2069	262
2070	262
2071	262
2072	13
2073	262
2075	436
2076	13
2077	262
2078	409
2079	436
2080	241
2081	437
2082	262
2083	262
2084	13
2085	438
2086	262
2087	13
2088	13
2090	109
2091	385
2092	439
2093	262
2095	132
2096	262
2098	440
2099	132
2100	262
2101	13
2102	140
2103	13
2104	262
2105	140
2106	441
2107	13
2108	13
2109	442
2110	443
2111	327
2113	262
2114	140
2115	11
2117	6
2120	407
2122	20
2123	11
2125	444
2126	445
2128	18
2129	11
2130	149
2137	446
2138	447
2140	448
2143	449
2144	327
2150	450
2153	451
2154	1
2156	452
2158	453
2161	9
2163	13
2165	11
2166	10
2167	11
2173	92
2175	13
2177	26
2178	11
2179	454
2181	13
2182	455
2183	24
2184	456
2185	457
2187	21
2190	13
2192	458
2193	11
2194	11
2195	27
2197	35
2200	459
2202	460
2203	140
2204	11
2205	461
2206	9
2207	26
2210	26
2211	462
2212	463
2213	27
2214	78
2215	1
2216	464
2218	13
2220	11
2221	3
2223	465
2224	31
2226	140
2227	466
2234	467
2235	468
2236	6
2238	11
2239	469
2240	470
2242	20
2243	11
2244	10
2246	471
2248	35
2249	11
2250	472
2254	6
2256	13
2257	34
2258	473
2261	31
2264	4
2265	474
2266	79
2269	359
2270	16
2274	1
2276	475
2277	11
2279	476
2281	16
2289	11
2290	477
2295	4
2296	478
2297	6
2298	2
2299	18
2300	11
2305	479
2306	480
2308	481
2309	482
2312	3
2314	6
2316	13
2319	4
2326	109
2327	19
2328	483
2329	484
2330	11
2331	485
2332	486
2333	487
2336	168
2339	11
2341	488
2345	21
2346	489
2348	18
2353	9
2355	11
2357	109
2358	11
2360	490
2361	13
2363	4
2367	78
2368	491
2370	26
2371	445
2373	27
2375	13
2376	4
2377	1
2379	492
2380	10
2381	493
2382	494
2383	13
2385	495
2387	496
2389	18
2391	9
2393	497
2394	498
2395	266
2398	11
2400	499
2402	486
2404	347
2405	500
2406	501
2409	502
2410	11
2411	4
2412	30
2413	6
2415	503
2416	504
2417	3
2419	3
2420	505
2421	506
2422	13
2424	11
2426	17
2427	24
2433	507
2434	4
2440	508
2443	509
2444	439
2447	510
2448	36
2451	20
2452	21
2454	13
2456	13
2459	511
2461	512
2462	513
2463	514
2466	27
2467	515
2468	44
2469	516
2470	13
2472	517
2474	355
2475	518
2478	18
2480	519
2481	19
2482	9
2485	520
2487	11
2489	9
2490	521
2494	522
2495	523
2496	6
2499	524
2501	525
2502	247
2504	1
2506	11
2507	26
2509	526
2510	19
2512	527
2513	120
2515	24
2519	528
2520	529
2521	11
2522	4
2523	11
2524	241
2525	34
2526	17
2527	13
2528	530
2530	531
2532	532
2533	533
2537	534
2539	535
2540	536
2543	537
2545	17
2547	10
2550	11
2555	407
2557	538
2559	539
2560	33
2561	34
2565	3
2567	5
2569	6
2571	540
2572	541
2573	26
2574	21
2575	542
2576	10
2577	4
2578	6
2579	13
2582	26
2583	543
2584	36
2587	1
2588	146
2592	5
2596	4
2599	26
2600	544
2601	545
2604	546
2605	48
2606	11
2608	547
2609	548
2610	549
2611	25
2614	21
2615	37
2617	26
2619	11
2620	13
2621	9
2622	550
2627	6
2628	4
2631	30
2634	551
2637	552
2638	6
2640	4
2641	553
2642	13
2643	554
2645	555
2647	10
2649	1
2650	493
2651	11
2653	18
2655	523
2657	556
2658	557
2659	558
2660	523
2662	559
2663	11
2664	560
2665	11
2667	561
2671	562
2672	4
2673	4
2676	563
2681	564
2682	16
2686	515
2687	565
2688	566
2689	4
2691	567
2693	568
2694	13
2695	109
2696	569
2697	570
2701	26
2702	13
2703	571
2705	572
2708	13
2711	27
2712	573
2713	1
2716	4
2720	31
2724	574
2725	10
2726	4
2727	445
2728	575
2729	576
2731	577
2734	26
2735	578
2736	16
2737	31
2739	4
2742	579
2745	580
2751	13
2755	11
2757	17
2759	581
2760	582
2761	583
2763	584
2764	439
2767	585
2768	11
2772	586
2775	31
2779	587
2782	25
2787	577
2790	588
2793	262
2794	589
2795	590
2797	1
2799	37
2800	591
2801	26
2802	592
2803	593
2810	594
2811	6
2812	11
2813	9
2814	595
2815	26
2817	596
2818	597
2821	31
2823	598
2824	31
2825	599
2829	600
2830	26
2831	17
2833	27
2834	601
2835	1
2839	602
2843	603
2845	16
2847	604
2848	20
2849	13
2850	11
2851	6
2852	605
2853	4
2855	606
2856	11
2857	607
2858	608
2860	609
2861	610
2863	262
2864	9
2865	611
2866	612
2868	18
2869	613
2871	614
2872	615
2874	616
2877	617
2879	618
2881	13
2883	4
2887	6
2889	3
2891	5
2892	619
2894	589
2895	13
2899	620
2901	6
2904	481
2908	31
2909	621
2910	156
2911	13
2912	622
2914	623
2917	624
2918	1
2919	625
2921	626
2922	627
2923	10
2924	31
2926	13
2927	628
2928	629
2929	327
2932	293
2937	3
2938	6
2940	630
2943	11
2948	486
2949	631
2951	632
2954	140
2955	45
2961	633
2962	25
2963	16
2964	11
2965	4
2966	6
2967	13
2968	11
2971	634
2972	17
2973	635
2974	6
2975	636
2977	637
2978	26
2979	638
2980	639
2982	640
2986	641
2988	642
2989	643
2990	644
2992	48
2993	34
2995	9
2997	529
2998	31
2999	13
3000	10
3004	645
3005	646
3006	3
3007	1
3009	647
3013	31
3014	13
3015	13
3019	493
3020	585
3023	117
3026	13
3027	648
3028	27
3031	649
3033	6
3035	34
3036	16
3039	17
3040	650
3041	651
3043	13
3045	652
3047	653
3050	519
3051	654
3054	44
3058	11
3061	5
3062	16
3066	11
3067	16
3068	11
3070	1
3073	655
3075	656
3077	657
3078	26
3079	658
3080	17
3082	526
3084	659
3085	100
3086	17
3087	13
3088	660
3089	20
3091	11
3093	661
3094	10
3096	13
3098	662
3103	248
3106	100
3107	17
3108	663
3109	109
3112	4
3115	11
3116	34
3117	31
3118	293
3119	16
3120	664
3124	665
3129	11
3130	666
3131	26
3132	667
3133	26
3134	668
3135	5
3138	669
3139	11
3140	11
3141	13
3143	3
3144	670
3147	11
3150	671
3151	17
3154	9
3155	672
3157	673
3160	17
3162	9
3163	383
3165	189
3166	5
3169	25
3170	674
3171	1
3173	118
3174	4
3177	13
3178	675
3181	3
3182	5
3184	9
3185	676
3189	11
3190	26
3192	677
3193	9
3194	11
3195	678
3196	6
3197	26
3198	27
3200	13
3202	6
3207	679
3209	16
3211	16
3212	27
3213	680
3214	681
3216	17
3217	682
3218	683
3219	684
3220	273
3221	13
3224	4
3227	685
3228	686
3232	687
3233	11
3235	16
3236	688
3237	31
3239	31
3240	13
3248	247
3251	5
3252	1
3253	689
3255	1
3256	3
3259	273
3262	523
3265	690
3269	691
3272	17
3273	692
3274	5
3275	693
3278	694
3280	34
3282	695
3287	6
3288	4
3289	696
3290	11
3291	697
3294	149
3295	31
3296	34
3299	109
\.


--
-- Data for Name: podcastratings; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.podcastratings (userid, podcastid, rating) FROM stdin;
\.


--
-- Data for Name: podcasts; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.podcasts (id, rssfeed, title, author, description, thumbnail) FROM stdin;
196	http://americancasinoguide.libsyn.com/rss	americancasinoguide's Podcast	Steve Bourie	The American Casino Guide is the  #1 bestselling book in the U.S. on the subject of casino gambling and casino travel.\n\nOn each show the book's author, Steve Bourie, talks about topics of interest to travelers who like to visit casinos.\n\nWhether it's using the best gambling strategies or simply getting the best deals on travel to casinos, Steve can speak expertly on the subject. During the course of each show, Steve also features an interview with a special guest from the world of casino travel or gambling.	http://static.libsyn.com/p/assets/1/d/4/d/1d4d983ac83c6631/CasinoCover_frt_2019.jpg
198	http://americanmonetaryassociation.org/category/video-podcast/feed/	Video Podcast – American Monetary Association	\N	– By The Jason Hartman Foundation	\N
199	http://amtrak.adventgx.com/rss.php?from=DEM&to=ELP	\n\t\t\tDEM to ELP\t\t	National Railroad Passenger Corporation (Amtrak)	\n\t\t\t\t\t\t\tAmtrak, the National Park Service's Trails and Rails Program, and the Department of Recreation, Park and Tourism Sciences at Texas A&M University have created podcasts to enhance your travel on the Sunset Limited train between New Orleans and Los Angeles. \n\t\t\t\t\t	http://amtrak.adventgx.com/images/podcasts/sunset_limited_sm.jpg
200	http://amtrak.adventgx.com/rss.php?from=DEM&to=LDB	\n\t\t\tDEM to LDB\t\t	National Railroad Passenger Corporation (Amtrak)	\n\t\t\t\t\t\t\tAmtrak, the National Park Service's Trails and Rails Program, and the Department of Recreation, Park and Tourism Sciences at Texas A&M University have created podcasts to enhance your travel on the Sunset Limited train between New Orleans and Los Angeles. \n\t\t\t\t\t	http://amtrak.adventgx.com/images/podcasts/sunset_limited_sm.jpg
201	http://amtrak.adventgx.com/rss.php?from=ELP&to=DEM	\n\t\t\tELP to DEM\t\t	National Railroad Passenger Corporation (Amtrak)	\n\t\t\t\t\t\t\tAmtrak, the National Park Service's Trails and Rails Program, and the Department of Recreation, Park and Tourism Sciences at Texas A&M University have created podcasts to enhance your travel on the Sunset Limited train between New Orleans and Los Angeles. \n\t\t\t\t\t	http://amtrak.adventgx.com/images/podcasts/sunset_limited_sm.jpg
156	http://allamericangunpodcast.blogspot.com/feeds/posts/default	All-American Gun Podcast	\N	\N	\N
204	http://amtrak.adventgx.com/rss.php?from=MRC&to=YUM	\n\t\t\tMRC to YUM\t\t	National Railroad Passenger Corporation (Amtrak)	\n\t\t\t\t\t\t\tAmtrak, the National Park Service's Trails and Rails Program, and the Department of Recreation, Park and Tourism Sciences at Texas A&M University have created podcasts to enhance your travel on the Sunset Limited train between New Orleans and Los Angeles. \n\t\t\t\t\t	http://amtrak.adventgx.com/images/podcasts/sunset_limited_sm.jpg
205	http://amtrak.adventgx.com/rss.php?from=YUM&to=MRC	\n\t\t\tYUM to MRC\t\t	National Railroad Passenger Corporation (Amtrak)	\n\t\t\t\t\t\t\tAmtrak, the National Park Service's Trails and Rails Program, and the Department of Recreation, Park and Tourism Sciences at Texas A&M University have created podcasts to enhance your travel on the Sunset Limited train between New Orleans and Los Angeles. \n\t\t\t\t\t	http://amtrak.adventgx.com/images/podcasts/sunset_limited_sm.jpg
224	http://animatuspodcast.blogspot.com/feeds/posts/default?alt=rss	Animatus | New Music at the University of Kansas	\N		\N
225	http://angryrobotbooks.com/feed/podcast/	Angry Robot	Angry Robot Books		http://angryrobotbooks.com/wp-content/uploads/2009/02/bw_7cm_300dpi.jpg
226	http://anonymous-band.weebly.com/uploads/1/8/0/6/18069839/vatsimpod.xml	All About Vatsim:	Chris Pierce	This podcast is designed for FS tutorials and different news about VATSIM	http://www.weebly.com/uploads/1/8/0/6/18069839/vatsim.png
227	http://animalcast.libsyn.org/rss	animalcast's Podcast		Another great podcast hosted by LibSyn.com	http://static.libsyn.com/p/assets/c/e/c/7/cec74f5a804d1212/soapy.png
228	http://anthonysaudiojournal.libsyn.com/rss	Anthony's Audio Journal	Anthony Jones	Hiking and Backpacking podcast of Anthony's personal journals from hikes and backpack trips in and around the Southern California area and the Eastern Sierras.	http://static.libsyn.com/p/assets/5/9/2/3/5923b6373f1357df/AAJ_Icon.jpg
229	http://aorta-web.seesaa.net/index20.rdf	aorta "RADIO GA GA!!"	aorta	\N	http://aorta-web.up.seesaa.net/image/podcast_artwork.jpg
230	http://aonpodcast.com/feed/podcast	Apropos of Nothing Podcast	Apropos of Nothing Podcast	Buckle Up for the Sex!	http://aonpodcast.com/wp-content/uploads/2016/07/AoN-logo.jpg
206	http://analogscience.seesaa.net/index20.rdf	ANALOG SCIENCE のラジオ♪	ERROR: NOT PERMITED METHOD: nickname 	ANALOG SCIENCEの面々がお届けするラジオ毎週月曜日アップ毎週メンバーが変わり、番組の内容も変わるユニークなラジオ活動のメインである音楽の話や恋話 映画や漫画 グダグダな話皆さんを飽きさせぬようメンバー一丸となってがんばりますんでよろしくお願いします各週の番組内容と出演者一週目：HANRさんとFLOW長寿さん 企画名：「県北の濃い二人による宴会」 二週目：NBさんとMATさん 企画名：「新日本ラジオ」 三週目：らいでんさんとLIBOOさん 企画名：「映画とか漫画とか見て感想の食い違いを楽しむ会」 四週目：PELOさんとキッコーマンさん 企画名：「日本語ラップの未来」	\N
208	http://amtrak.adventgx.com/line_rss.php?line=1&direction=west	SAS to LAX	National Railroad Passenger Corporation (Amtrak)	\n\t\t\t \n\t\t\t\tAmtrak, the National Park Service's Trails and Rails Program, and the Department of Recreation, Park and Tourism Sciences at Texas A&M University have created podcasts to enhance your travel on the Sunset Limited train between New Orleans and Los Angeles.\n\t\t\t \n\t\t	http://amtrak.adventgx.com/images/podcasts/sunset_limited_sm.jpg
209	http://amtrak.adventgx.com/line_rss.php?line=1&direction=east	LAX to SAS	National Railroad Passenger Corporation (Amtrak)	\n\t\t\t \n\t\t\t\tAmtrak, the National Park Service's Trails and Rails Program, and the Department of Recreation, Park and Tourism Sciences at Texas A&M University have created podcasts to enhance your travel on the Sunset Limited train between New Orleans and Los Angeles.\n\t\t\t \n\t\t	http://amtrak.adventgx.com/images/podcasts/sunset_limited_sm.jpg
210	http://anatolyice.ru/?feed=podcast	Funk and Beyond	Anatoly Ice	Carefully constructed segmets of funk, soul, jazz, disco, hip-hop, afro, brazilian beats, breaks and other things we like	http://anatolyice.ru/wp-content/uploads/powerpress/fmgu_ff1-164-652.jpg
212	http://andeveryonesadj.jellycast.com/podcast/feed/3	....andeveryonesadj	andeveryonesadj	From the people who brought you ....andeveryonesadj.com, the music blog.	https://andeveryonesadj.jellycast.com/files/final%20black%20bevel%20300.jpg
213	http://andrewpalms.sermondrop.com/sermons.rss	Sermondrop Main Feed	Sermondrop.com	Sermon audio from Sermondrop.com	\N
214	http://andski.net/podcast/selected.xml	Selected Radio with Andski	Andski	Every month -the best in progressive, tech and trance	http://andski.net/default_selected2.jpg
215	http://andy67.podomatic.com/rss2.xml	alternative news talk	andy ravens	your host the fatman & co host dillion are back with there own show\r\n\r\nhttp://nextgenerationwrestlingsociety.weebly.com/	https://assets.podomatic.net/ts/59/24/a5/andy67/3000x3000_6275636.jpg
216	http://andysavage.net/swx/pp/media_archives/160172/channel/2575/series/5342.xml	The Andy Savage Show	Andy Savage	The Andy Savage Show: Andy Savage makes marriage, parenting and family life make sense. The Andy Savage Show airs every Wednesday at 3pm on AM640 LIVE from Memphis, TN reaching eight states and available for the world right here on the podcast. Every episode is full of Biblical truth, practical wisdom and a little humor to give you the tools to make you home a little better place. To learn more about Andy and to stay connected to the Andy Savage Show please visit andysavage.com and follow on Twitter @makesense & @andysavageshow. Thanks for listening!\n	http://andysavage.net/assets/2281/icon-722x5.png
217	http://andydell.podbean.com/feed/	Jesus Christ is here NOW!	Various Authors and Revivalists	Christian Revivalists working through the miracle power of Holy Spirit today, preparing the saints for the coming of Jesus (Yeshua)	https://pbcdn1.podbean.com/imglogo/image-logo/109741/logo.jpg
437	http://auburnfootballinsider.blogspot.com/feeds/posts/default?alt=rss	Auburn Football Insider	\N	A view of Auburn Football from a former Auburn Football Manager	\N
191	http://alteredstates.planetparanormal.com/?feed=podcast	Altered States Paranormal Radio	Altered States Paranormal Internet Radio	Real paranormal radio by researchers, for researchers	http://www.tomyd.com/AS_SquareLogo.jpg
192	http://alsoinaudio.com/rss/SCKlart.xml	Klart!	David Stiernholm	Poddradioprogrammet om god struktur, att ha koll på läget och få mer tid över; för dig personligen och i din organisation.\r\n(Also available in an English version, titled Done!)	http://www.alsoinaudio.com/klart-1400x1400.jpg
193	http://alternativlos.org/alternativlos.rss	Alternativlos	Felix von Leitner, Frank Rieger	Alternativlos ist der Boulevard-Podcast von Frank und Fefe, über Politik, Technik, Verschwörungstheorien und worauf wir sonst noch so Lust haben.  Der Name orientiert sich an der Lieblingsbegründung von Politikern für ihre Vorhaben (in Begründungen von Gesetzen heißt es praktisch immer den Absatz „Alternativen: keine“).	http://alternativlos.org/squarelogo.png
207	http://ananaz.net/rpcast/megalofone.xml	Megalofone	\N	programa radiofónico desenvolvido por alunos da ESAD.CR	http://www.ananaz.net/rpcast/lovethathidefsound600.jpg
126	http://adorador10.blogspot.com/feeds/posts/default	La vida de un Adorador	\N	\N	\N
2	http://feeds.feedburner.com/dancarlin/history	Hardcore History	Dan Carlin	In "Hardcore History" journalist and broadcaster Dan Carlin takes his "Martian", unorthodox way of thinking and applies it to the past. Was Alexander the Great as bad a person as Adolf Hitler? What would Apaches with modern weapons be like? Will our modern civilization ever fall like civilizations from past eras? This isn't academic history (and Carlin isn't a historian) but the podcast's unique blend of high drama, masterful narration and Twilight Zone-style twists has entertained millions of listeners.	http://www.dancarlin.com/graphics/DC_HH_iTunes.jpg
3	http://feeds.soundcloud.com/users/soundcloud:users:211911700/sounds.rss	Chapo Trap House	Chapo Trap House	Podcast by Chapo Trap House	http://i1.sndcdn.com/avatars-000230770726-ib4tc4-original.jpg
231	http://apeinfinitum.net/wcsf/rss.xml	WRITE CLUB SF	Steven Westdahl and Casey Childers	Literature as bloodsport. Prize money to charity.	http://apeinfinitum.net/wcsf/images/itunes.jpg
232	http://annebachrach.hipcast.com/rss/theaccountabilitycoach.xml	The Accountability Coach: Business Acceleration|Productivity	Anne Bachrach	Proven Business Success Systems for Working Less, Making More Money, and Having a More Balanced and Successful Life.\r\n\r\nIf you want to accelerate your results so you can enjoy your ideal business and life sooner rather than later, you came to the right place. \r\n\r\nWouldn’t it be great if our ‘good intentions’ worked the way that we think they should?  Not even enthusiasm guarantees positive results. There’s often a wide gap between our intentions and our actions.  We fail to take the action necessary to be in alignment with our good intentions. This can be very frustrating.  \r\n\r\nGood intentions don’t magically lead to good results. They are a start; however, they are unfortunately not enough. This is just the truth!  We all can use a little accountability in our life to help us stay focused so we can achieve all our goals in the time frames we desire.  \r\n\r\nAnne Bachrach is author of Excuses Don't Count; Results Rule!, and Live Life with No Regrets; How the Choices we Make Impact our Lives; The Work Life Balance Emergency Kit; and co-author of Roadmap to Success with Stephen Covey and Ken Blanchard.  Create the kind of life you have always dreamed of having.  Go to https://www.AccountabilityCoach.com/landing today and take advantage of 3 Free gifts that you can immediately use to help you achieve your professional and personal goals.\r\n\r\nVisit https://www.AccountabilityCoach.com and receive 10% off all products and services along with many complimentary high-value resources and tools available to you under the FREE Silver Membership.  Check out the Quality of Life Enhancer™ Exercise, and the Wheel of Life exercise, for helping you find balance in everyday life to name a few.\r\n\r\nSubscribe to the Accountability Coach YouTube channel and Blog to receive even more valuable information so you can have the kind of life you truly want and deserve.\r\n\r\n- Anne Bachrach's YouTube channel (https://www.youtube.com/annebachrach)\r\n\r\n- Anne Bachrach's Business Success Principles Blog (https://www.accountabilitycoach.com/blog/)	https://annebachrach.hipcast.com/albumart/1000_itunes_1603052920.jpg
233	http://api.hans-knoechel.de/hs/podcast.xml	Meilenstein 3	Hans Knöchel	Fuer das Praktikum im Bereich Audio & Videotechnik wurde eine Newssenung gedreht und publiziert.	http://hans.to/go/campusTV.jpg
234	http://api.mediasuite.multicastmedia.com/ws/get_rss/p_e0c1m90k/thumbs_true/e0c1m90k.xml	David's 400 Podcast	REDEEMED		\N
235	http://api.mediasuite.multicastmedia.com/ws/get_rss/p_hss7mcuq/thumbs_true/hss7mcuq.xml	Christ Fellowship Audio Podcast	Christ Fellowship	Audio podcast of Christ Fellowship Church, Palm Beach Gardens, Florida. Pastors Todd Mullins, Tom Mullins and John Maxwell.	\N
236	http://api.mediasuite.multicastmedia.com/ws/get_rss/p_i2wp9i3q/thumbs_true/i2wp9i3q.xml	Connecting Point with Dr. Mike Hamlet - Audio Podcast	First Baptist Church of North Spartanburg	Weekly messages from God's Word by Dr. Michael S. Hamlet, Pastor, First Baptist North Spartanburg.	http://thumb-enterprise.piksel.com/thumbs/tid/t1331578669/3118827.jpg
237	http://api.mediasuite.multicastmedia.com/ws/get_rss/p_r8n1rvu3/thumbs_true/allfiles_true/download_true/lang_en-us/icategory_Christianity/r8n1rvu3.xml	Bishop Joseph W. Walker, III Video Podcast	Mt. Zion Baptist Church	Ministered by Bishop J.W. Walker III,  get a weekly dose of Gods Word through practical teaching and preaching for inspiration and application to your life.	http://player.piksel.com/media/1084/images/1400x1400_JWW3_podcast_new-3228039-djkx6rd9.jpg?c=2016-12-09+16%3A53%3A50
194	http://americaneg.vo.llnwd.net/o16/usta/usta_videos/florida/audio/The_G-Cast_Your_Guide_to_Junior_Tennis_in_Florida.xml	The G-Cast - Your Guide to Junior Tennis in Florida	Andy Gladstone	The G-Cast is your one stop source for everything related to JUNIOR TENNIS IN FLORIDA...interviews with future stars and  elite high performance coaches, insightful commentary, product reviews and more...	http://assets.usta.com/assets/651/15/G-Cast_300x300.jpg
195	http://amberlove.hipcast.com/rss/vodkaoclock.xml	VODKA O'CLOCK	AmberUnmasked	Grab a drink of your choice, whether a martini or a hot tea, and enjoy the show with people from different areas of Arts & Entertainment.	https://amberlove.hipcast.com/albumart/1000_itunes_1602592167.jpg
197	http://americanmonetaryassociation.hartmannetwork.libsynpro.com/rss	American Monetary Association	Jason Hartman	The American Monetary Association is a non-profit venture funded by The Jason Hartman Foundation that is dedicated to educating people about the practical effects of monetary policy and government actions on inflation, deflation and freedom. Our goal is to help people prosper in the midst of uncertain economic times.\r\n\r\nThe American Monetary Association believes that a new and innovative understanding of wealth, value, business and investment is necessary to thrive in the new reality of big government, big deficits and monetary destruction.\r\n\r\nHost, Jason Hartman, interviews top-tier guests, bestselling authors and financial experts including; Robert Kiyosaki (Rich Dad), Harry Dent (The Great Depression Ahead), Peter Schiff (Crash Proof), William Cohan (House of Cards), Ellen Brown (Web of Debt), Thomas Woods (Meltdown), Gerald Celente (Trends Journal), G. Edward Griffin (The Creature from Jekyll Island), Chris Mayer (Capital & Crisis), Chris Martenson (The Crash Course), Robert Prechter (Elliott Wave), Pat Buchanan (Presidential Candidate), Eric Tyson (Investing for Dummies), Addison Wiggin & Bill Bonner (Agora – The Daily Reckoning), Catherine Austin Fitts (Solari), Thomas Sowell (The Hoover Institution), Marc Chandler (Making Sense of the Dollar), Gillian Tett (Fool’s Gold & The Financial Times), Howard Ruff (Prosper In The Coming Bad Years), Larry Parks (Gold Wars & FAME), James West (Crime of the Century), Les Leopold (The Looting of America), Robert Wiedemer (Aftershock), Bill Whittle (Rich Man Poor Man), Les Leopold (The Looting of America), Robert R. Prechter (Elliot Wave Theory), Lowell Ponte (The Great Withdrawal), Jack Gerard (American Petroleum Institute), Jeffrey Hirsch (Stock Trader's Almanac), Jim Bruce (Money For Nothing: Inside the Federal Reserve), Kevin Armstrong (Bulls, Birdies, Bogies, and Bears), Laurence Kotlikoff (The Clash of Generations), Shaun Rein (The End of Cheap China), \r\n\r\nA trademark feature of Hartman Media podcasts are our 'Tenth Episodes' where alternative topics of interest are explored every tenth episode. This provides a diverse mix of programming exploring issues and influential authors like Hannah Holmes (What Is Your Personality Type), Dr. Gary Chapman (The Five Love Languages), Christine Hassler (Manage Your Expectations), Sam Carpenter (Work the System), Chuck Gallagher (Second Chances), John J. Murphy (Zentrepreneur), and Robert Greene (Mastery). \r\n\r\nTopics explored at depth by the American Monetary Association include Bitcoin, digital currencies, investing, corporate tax inversions, crowdfunding, inflation, the Federal Reserve, student loan debt, monetary policy, economic challenges facing generation Y, solar energy, 3D printing, medical technology, US dollar, currency exchange, plunging bond rates, personal and commercial bankruptcy, the cost of a college education, digital banking, the American dream, capital gains taxes, asset protection, gold and silver, commodities markets, precious metals, investing tips, structural and personal unemployment, bank regulations, regulatory reform, emerging markets, shadow banking, social media, derivatives, mobile commerce, government regulation, housing market, identity theft, cyber currencies, mortgage lenders, investment properties, VA loans, gold standard, Fannie Mae, Freddie Mac, online auctions, landlord tenant conflicts, tax lien investing, tax law, retirement, contract law, stagflation, home loans, real estate scams, renters, reverse mortgages, foreclosures, euro, European Union, ECB, European Central Bank, the US housing market, micro lending, online security, cyber security, online banking, digital banking, outsourcing, online shopping, Amazon, Apple, Facebook, Twitter, JP Morgan, short sales, austerity, forex, monetary systems, budget surplus, budget deficits, tax cuts, solar energy, consumer debt, consumer price index, property investing, high frequency trading, interest rates, college tuition, cashless societies, credit card debt, credit monitoring, credit ratings, currency trading, refinancing, federal stimulus, financial independence, financial planning, financial literacy, economic growth, economic development, Wall Street, IPO, IRS, Internal Revenue Service, IMF, International Monetary Fund, mobile banking, Elliot Wave Theory, free trade, underwater homeowners, foreign investing, oil prices, entrepreneurship, Equifax, federal budget, Keynes, Keynesian, fiat currency, financial scams, global economy, gold standard, income tax, and foreign investment.	http://static.libsyn.com/p/assets/e/a/0/1/ea01b27429b5d851/AMA_square_1400x1400_itunes.jpg
238	http://api.mediasuite.multicastmedia.com/ws/get_rss/p_w6fo84x2/thumbs_true/w6fo84x2.xml	The Higher Level	The Potter's House of Denver	The Higher Level is a weekly broadcast of encouragement and inspiration with Dr. Chris Hill, the Senior Pastor of The Potter's House of Denver.	\N
239	http://api.mediasuite.multicastmedia.com/ws/get_rss/p_q0b7er71/thumbs_true/q0b7er71.xml	CF//YA LIVE Audio Podcast	Christ Fellowship	Audio podcast for the ministry of J1Ten of Christ Fellowship Church, South Florida. A ministry dedicated to individuals 20-39.	\N
240	http://api.mediasuite.multicastmedia.com/ws/get_rss/p_ycvk6036/thumbs_true/ycvk6036.xml	Christ Fellowship Video Podcast	Christ Fellowship	Video podcast of Christ Fellowship Church, Palm Beach Gardens, Florida. Pastors Todd Mullins, Tom Mullins and John Maxwell.	\N
241	http://api.mediasuite.multicastmedia.com/ws/get_rss/p_z206n93e/	Video On-Demand (iPhone)	FIRST BAPTIST CHURCH ORLANDO	Watch the un-cut recording of First Baptist Orlando's weekend services.	\N
242	http://api.mediasuite.multicastmedia.com/ws/get_rss/p_g9288z94/thumbs_true/allfiles_true/download_true/lang_en-us/icategory_Business/g9288z94.xml	Hebron Baptist Church Podcast	HEBRON BAPTIST CHURCH	This is the weekly podcast of Hebron Baptist Church in Dacula, GA.  These podcast primarily contain the Sunday Morning Service at Hebron with our Lead Pastor Landon Dowden. You can find us at hebronchurch.org	http://player.piksel.com/media/2969/images/HebronPodcast-1-3622977-cpe7gkyd.jpg?c=2018-11-15+22%3A02%3A23
243	http://api.mediasuite.multicastmedia.com/ws/get_rss/p_z86on29v/thumbs_true/z86on29v.xml	Hebron College and  20s	HEBRON BAPTIST CHURCH	This Is the weekly podcast of the College and 20s Sunday night service. Flip Johnson our college and 20s pastor leads this ministry based in Dacula, GA. hebronchurch.org 	http://thumb-enterprise.piksel.com/thumbs/tid/t1555341247/12458474.jpg
244	http://api.multicastmedia.com/ws/get_rss/p_w62ve2u2/thumbs_true/w62ve2u2.xml	AgPhd Video Player	IFA Productions inc.	Information for Agriculture	http://thumb-enterprise.piksel.com/thumbs/tid/t1501091078/11388233.jpg
245	http://api.multicastmedia.com/ws/get_rss/p_mt5063eu/thumbs_true/allfiles_true/download_true/lang_en-us/icategory_Religion_&_Spirituality/mt5063eu.xml	Lyle & Deborah Dukes Ministries Podcast	Lyle and Deborah Dukes Ministries / Harvest Life Changers		\N
246	http://api.mediasuite.multicastmedia.com/ws/get_rss/p_x1v9gem5/thumbs_true/x1v9gem5.xml	Radio WAVE	Caritas of Birmingham	Radio WAVE Live Shows, and Re-Broadcasts. Featuring Shows Every 25th and 2nd of the Month, with Host A Friend of Medjugorje	http://thumb-enterprise.piksel.com/thumbs/aid/w/h/t1601087015/3840887.jpg
247	http://api.sr.se/api/rss/pod/15373	Vad är meningen med Johannes Anyuru	Sveriges Radio	Från 2011. Författaren Johannes Anyuru ser tillbaka på förälskelser, politisk berusning och religiöst vacklande och söker svar på några av teserna om meningen med tillvaron.\r\nAnsvarig utgivare: Ylva M Andersson	https://static-cdn.sr.se/images/4125/2401810_512_512.jpg?preset=api-itunes-presentation-image
248	http://api.videos.ndtv.com/apis/podcast/index/client_key/ndtv-podcast-5d35e3e34a92df17d11d54e0ff241e8b?shows=346&showfull=1&media_type=audio&extra_params=keywords,description	Your Call	NDTV	Your Call gives you a chance to speak directly to India's big newsmakers. Join Sonia Singh and her guests from across the gamut of business, entertainment and politics for a mix of interviews and topical discussions.	http://drop.ndtv.com/tvshows/show_346_1337345460.jpg
249	http://api.sr.se/api/rss/pod/14426	Organshopping	Sveriges Radio	Från 2011. Vetenskapsradion granskar den globala handeln med organ.\r\nAnsvarig utgivare: Andreas Miller	https://static-cdn.sr.se/images/4078/2395662_512_512.jpg?preset=api-itunes-presentation-image
250	http://api.sr.se/api/rss/pod/9848	Vi i femman	Sveriges Radio	Frågetävlingen för alla femteklassare. Kan du svaren?\r\nAnsvarig utgivare: Hanna Toll	https://static-cdn.sr.se/images/3033/65218a73-0595-4a75-a6aa-beaded375843.jpg?preset=api-itunes-presentation-image
251	http://api.sr.se/api/rss/pod/11469	Skriv!	Sveriges Radio	Från 2010. Författarna Elsie Johansson och Jerker Virdborg läser texter från lyssnarna.\r\nAnsvarig utgivare: Cecilia Bodström	https://static-cdn.sr.se/images/3809/2396455_512_512.jpg?preset=api-itunes-presentation-image
252	http://api.sr.se/api/rss/pod/17228	Detektor	Sveriges Radio	Från 2012. Förklarar och blottlägger fakta i debatt, politik, medier och fikarum.\r\nAnsvarig utgivare: Cecilia Bodström	https://static-cdn.sr.se/images/4300/2186541_512_512.jpg?preset=api-itunes-presentation-image
253	http://api.sr.se/api/rss/pod/12664	Historiska ord	Sveriges Radio	Från 2012. Jan-Öjvind Swahn berättar om bakgrunden till historiska ord och namn.\r\nAnsvarig utgivare: Cecilia Bodström	https://static-cdn.sr.se/images/3954/2359375_512_512.jpg?preset=api-itunes-presentation-image
254	http://api.sr.se/api/rss/pod/15445	Sommar i P4 Dalarna	Sveriges Radio	Sidan uppdateras inte. \r\nAnsvarig utgivare: Anna Gullberg	https://static-cdn.sr.se/images/2080/2752588_512_512.jpg?preset=api-itunes-presentation-image
255	http://api.sr.se/api/rss/pod/8424	Knarket	Sveriges Radio	Från 2009. En blogginspirerad reportageserie i fyra delar som handlar om drogsverige.\r\nAnsvarig utgivare: Staffan Sillén	https://static-cdn.sr.se/images/3577/2394501_512_512.jpg?preset=api-itunes-presentation-image
256	http://api.sr.se/api/rss/pod/9707	Lyssnarens guide till galaxen	Sveriges Radio	Från 2009. \r\nAnsvarig utgivare: Cecilia Bodström	https://static-cdn.sr.se/images/3693/2938036_512_512.jpg?preset=api-itunes-presentation-image
202	http://amtrak.adventgx.com/rss.php?from=LDB&to=DEM	\n\t\t\tLDB to DEM\t\t	National Railroad Passenger Corporation (Amtrak)	\n\t\t\t\t\t\t\tAmtrak, the National Park Service's Trails and Rails Program, and the Department of Recreation, Park and Tourism Sciences at Texas A&M University have created podcasts to enhance your travel on the Sunset Limited train between New Orleans and Los Angeles. \n\t\t\t\t\t	http://amtrak.adventgx.com/images/podcasts/sunset_limited_sm.jpg
203	http://amtrak.adventgx.com/rss.php?from=MRC&to=TUC	\n\t\t\tMRC to TUC\t\t	National Railroad Passenger Corporation (Amtrak)	\n\t\t\t\t\t\t\tAmtrak, the National Park Service's Trails and Rails Program, and the Department of Recreation, Park and Tourism Sciences at Texas A&M University have created podcasts to enhance your travel on the Sunset Limited train between New Orleans and Los Angeles. \n\t\t\t\t\t	http://amtrak.adventgx.com/images/podcasts/sunset_limited_sm.jpg
1	http://www.hellointernet.fm/podcast?format=rss	Hello Internet	CGP Grey and Brady Haran	Presented by CGP Grey and Dr. Brady Haran.	https://images.squarespace-cdn.com/content/52d66949e4b0a8cec3bcdd46/1391195775824-JVU9K0BX50LWOKG99BL5/Hello+Internet.003.png?content-type=image%2Fpng
4	http://feeds.99percentinvisible.org/99percentinvisible	99% Invisible	Roman Mars	<![CDATA[<p>We're excited to celebrate the release of <strong><em><a href="https://99percentinvisible.org/book/" rel="nofollow" target="_blank">The 99% Invisible City</a></em></strong> book by host Roman Mars and producer Kurt Kohlstedt with a guided audio tour of beautiful downtown Oakland, California.</p>\n\n            <p>In this episode, we explain how anchor plates help hold up brick walls; why metal fire escapes are mostly found on older buildings; what impact camouflaging defensive designs has on public spaces; who benefits from those spray-painted markings on city streets, and much more.</p>\n\n            <p>Plus, At the end of the tour, stick around for a behind the scenes look at the book as we answer a series of fan-submitted questions about how it was created, offering a window into the writing, illustration and design processes.</p>\n\n            <p><a href="https://99percentinvisible.org/?p=34212&amp;post_type=episode" rel="nofollow" target="_blank">Exploring The 99% Invisible City</a></p>]]>	https://f.prxu.org/96/images/a52a20dd-7b8e-46be-86a0-dda86b0953fc/99-300.png
5	https://feeds.megaphone.fm/replyall	Reply All	Gimlet	"'A podcast about the internet' that is actually an unfailingly original exploration of modern life and how to survive it." - The Guardian. Hosted by PJ Vogt and Alex Goldman, from Gimlet.	https://images.megaphone.fm/_FDido6HoKbp_S5zoGyfMNxqbNgd4Qkn3IUnuObAV5A/plain/s3://megaphone-prod/podcasts/05f71746-a825-11e5-aeb5-a7a572df575e/image/uploads_2F1591157139331-y9ku7q9xzyq-9ab64ecee1420b68b238691e2d35b287_2FReplyAll-2019.jpg
6	http://podcasts.joerogan.net/feed	Joe Rogan (Podcast Site)	\N	\N	\N
123	http://adamritzshow.com/category/show/feed/	\n\tComments on: \t	\N		\N
44	http://06032012crossroads.podomatic.com/rss2.xml	WV Crossroads	WV Crossroads Church	The latest from Crossroads!!!	https://assets.podomatic.net/ts/ca/46/7c/podcast92189/3000x3000_6621708.jpg
257	http://api.sr.se/api/rss/pod/19417	Quizza med P3	Sveriges Radio	Sidan uppdateras inte. Quizza med P3 är Sveriges roligaste radiofrågesport. Samla ihop dina vänner eller tävla mot dig själv när Kringlan Svensson och Nanna Johannson utmanar med frågor.\r\nAnsvarig utgivare: Anne Sseruwagi	https://static-cdn.sr.se/images/4506/9886d864-eaf4-482a-90a6-4387e898d1a4.jpg?preset=api-itunes-presentation-image
45	http://107een.podOmatic.com/rss2.xml	KEEPITTHOROGH...d(®_®)b™	KEEPITTHOROGH...d(®_®)b™	848FILMS/GORiLLAHiTTT  BOINX TV Pro.FOOTAGE LOUNGE S H O W: wit THE VIBE ON THE STREET'S                         INTERVIEW'S-	https://assets.podomatic.net/ts/b7/86/e3/107een/1400x1400_8336118.jpg
258	http://api.sr.se/api/rss/pod/7146	Stockholm-Bryssel	Sveriges Radio	Från 2009. Ett reportage i fyra delar om politik mellan två maktcentrum.\r\nAnsvarig utgivare: Cecilia Bodström	https://static-cdn.sr.se/images/3403/2876687_512_512.jpg?preset=api-itunes-presentation-image
259	http://api.videos.ndtv.com/apis/podcast/index/client_key/ndtv-podcast-5d35e3e34a92df17d11d54e0ff241e8b?shows=125&showfull=1&media_type=audio&extra_params=keywords,description	Left, Right & Centre	NDTV	The day's biggest news dissected by the day's newsmakers. Diverse opinions from across the political spectrum. The show that makes you decide, are you the Left, Right or the Centre?	https://c.ndtvimg.com/2020-08/9tkgsogo_left-right-centre_640x480_14_August_20.png
260	http://api.videos.ndtv.com/apis/podcast/index/client_key/ndtv-podcast-5d35e3e34a92df17d11d54e0ff241e8b?shows=503&showfull=1&media_type=audio&extra_params=keywords,description	Truth vs Hype	NDTV	Truth vs Hype travels to the Ground Zero of the biggest story. Every week, re-defining reportage on Indian television.	https://i.ndtvimg.com/video/images/tvshows/show_503_1507207355.jpg
261	http://api.sr.se/api/rss/pod/17892	Sommardebatt	Sveriges Radio	Sidan uppdateras inte. En arena för meningsutbyten med kulturell, ideologisk och samtida botten. Programmet sänds åtta lördagar under sommaren i P1 och programledare är Louise Epstein och Henrik Torehammar. \r\nAnsvarig utgivare: Daniel af Klintberg	https://static-cdn.sr.se/images/4364/2363696_512_512.jpg?preset=api-itunes-presentation-image
262	http://api.sr.se/api/rss/pod/5206	Roll on med Mia och Klara i P4	Sveriges Radio	Från 2008. De bästa sketcherna från radioprogrammet med svärmodern Viveka Andebratt, 70-talsnostalgikern Bubban, porrfilmsskådisen Jasmina Svensson och många andra.\r\nAnsvarig utgivare: Dan Granlund	https://static-cdn.sr.se/images/3104/2937963_512_512.jpg?preset=api-itunes-presentation-image
477	http://huffduffer.com/Heronheart/collective/rss	Heronheart's collective on Huffduffer	\N	Heronheart's collective	https://huffduffer.com/images/podcast.jpg
46	http://12byzantinerulers.com/rss.xml	12 Byzantine Rulers: The History of The Byzantine Empire	Lars Brownworth	This lecture series by Lars Brownworth covers the history of the Byzantine Empire through the study of 12 of its greatest rulers.	http://12byzantinerulers.com/images/12-byzantine-rulers-badge.png
47	http://1029thehog.com/feed/bobnbrianod/	Bob and Brian Podcasts	102.9 The Hog	Everything That Rocks with Bob & Brian in the morning!	http://i1.sndcdn.com/avatars-000176688786-zogajk-original.jpg
74	http://Serialniytrendets.podfm.ru/rss/rss.xml	Подкасты пользователя Кураж-Бамбей.Ru	Кураж-Бамбей.Ru	\N	http://files.podfm.ru/images/avatar_default_150.png
57	http://22digital.com/afterparty/feed.xml	Modern Family: After Party Podcast	After Party	Join fellow fans as they talk about real life stories inspired by the latest episode of ABC's Emmy Award winning Modern Family. Hosted by your new friends, Matt, Mark, Heather, and Pete. With Special Guests Paul and Judy.	http://22digital.com/afterparty/images/itunes_image.jpg
58	http://36bou.seesaa.net/index20.rdf	podcast三十六房	podcast三十六房	大阪･日本橋のヘヴィメタル専門ショップS.A.MUSICからお届けするpodcast番組。出演･アサイリョウ(Ryo Asai) - S.A.MUSIC･ザッピー - ex-HR/HM Sounds Bar MEGAFORCE･しんどー - HEAVY METAL DISCO 鋼鉄之宴	http://36bou.up.seesaa.net/image/podcast_artwork.jpg
59	http://365.cast.ir/files/365/feed.xml	365 words	\N	365 کلام شنیدنی-هر روز 1 کلام	\N
60	http://4-cast.tv/iTunes.xml	4-Cast - The Barbershop Harmony Podcast	Alan LeVezu and Eric Brickson	4-Cast - The Barbershop Harmony Podcast	http://archive.4-cast.tv/HB4C_Logo.jpg.jpg
61	http://4774eba48e9e6a0f.lolipop.jp/pd.xml	Shiro Fukaya Podcast 	Shiro Fukaya 	Japanese producer and DJ Shiro Fukaya Podcast	http://www.shirofukaya.fuyu.gs/podcastlogo.jpg
62	http://48gfc.com/podcast/podcast.xml	Guerrilla Filmmakers Lounge	48GFC	Filmmaking as a competitive sport...  The 48 Hour Guerrilla Film Competition is your chance to write, shoot, edit and WIN!	http://48gfc.com/podcast/gfcbadge.jpg
63	http://52dainews.seesaa.net/index20.rdf	52大ニュース	52大ニュース	ほぼ毎週水曜日更新。国家認定一級うんちく士・黒鯱と、脳が全部右脳のT3000が、社会や科学やニュースについて話し合うネットラジオです。	http://52dainews.up.seesaa.net/image/podcast_artwork.png
64	http://4l160.com/blog/category/podcast/feed	4L 160のパイプ椅子クルージングZZ 番外編	4L160	ときに鋭くときに緩く世相の横っ面を4Lと160の二人がぶん殴る！ 4Lと160によるすっげぇ面白いwebラジオ！Podcastでも配信中！	http://kazz.zombie.jp/4l160images/pipeZZ_podcast.jpg
65	http://53rs.seesaa.net/index20.rdf	電子雑誌「+81-8041483156（プラスハチイチ）」	酒井りゅうのすけ／＠53RS	『個人メディアは新世界の夢を見るのか』個人メディアという物は、僕らを幸せに導いてくれるのか？電子書籍というフィールドで雑誌というメディア形態を使い、自分なりの答えを探しています。	http://53rs.up.seesaa.net/image/podcast_artwork.png
66	http://5by5.tv/rss	5by5 Master Audio Feed	5by5 and Dan Benjamin	5by5 - All Audio Broadcasts	http://5by5.tv/assets/5by5-itunes.jpg
67	http://6pod.sakura.ne.jp/rss.xml	漫画の現場☆ロクロウポッドキャスト！	後藤隼平&ロクロウ	新人漫画家の後藤隼平とベテランアシスタントのロクロウによる漫画ポッドキャストです！	http://6pod.sakura.ne.jp/sblo_files/6pod/image/rokuco300.jpg
221	http://anelegantweapon.podbean.com/feed/	An Elegant Weapon	J.M. Clark	Fankid chats and interviews for a more civilized age. Hosted by J.M. Clark	https://pbcdn1.podbean.com/imglogo/image-logo/397283/podbeanavatar.jpg
263	http://api.videos.ndtv.com/apis/podcast/index/client_key/ndtv-podcast-5d35e3e34a92df17d11d54e0ff241e8b?shows=264&showfull=1&media_type=audio&extra_params=keywords,description	India Decides @ 9	NDTV	Watch the biggest stories of the day.	http://drop.ndtv.com/tvshows/show_264_1363592025.jpg
68	http://5minutesofrum.com/episodes?format=rss	5 Minutes of Rum	Kevin Upthegrove	Notes on rum, a few minutes at a time. Exploring rum as a spirit as well as an ingredient in both new and classic tiki cocktail recipes. Rum not included.	https://images.squarespace-cdn.com/content/514f6341e4b0a337a815f5dc/1365382616912-8IR7EGMKLZUHSS47DMPL/5+min+of+rum+logo+with+text.jpg?content-type=image%2Fjpeg
127	http://acongruentlife.net/feed/podcast	A Congruent Life	Andy Gray	Inspirational Stories of Authenticity and Happiness	http://acongruentlife.net/images/acllogo-1400.jpg
128	http://adultadhdbook.com/?feed=podcast	More Attention, Less Deficit	Dr. Ari Tuckman	Success Strategies for Adults with ADHD	http://clear-window.flywheelsites.com/wp-content/uploads/powerpress/MoreAttentionLessDeficit.jpg.jpeg
129	http://aboutradio.org/feed/	about:radio	Bernd	Bernd macht Radio über die Internets	http://i43.tinypic.com/vi2kht.jpg
130	http://addcomedy.libsyn.com/rss	A.D.D. Comedy with Dave Razowsky	Dave Razowsky	On "ADD Comedy with Dave Razowsky,” guests from the worlds of comedy, theatre, film, television, and literature discuss their journeys and life philosophies with podcast host David Razowsky. David’s an alum of The Second City Chicago where he performed with Steve Carell, Stephen Colbert, Amy Sedaris and numerous others. He’s the former artistic director of The Second City Hollywood, is a member of The Reduced Shakespeare Company, served as a consultant for Dreamworks, and taught for Steppenwolf Theatre Company. David is a master teacher of improvisation, a gifted improv actor and director, and performs and teaches all over the world. He can be reached at dave@addcomedy.com.	http://static.libsyn.com/p/assets/1/d/6/a/1d6a412baba5fc96/ADD_FINAL_One_1400pxX1400px.png
37	http://1153friend.seesaa.net/index20.rdf	永井真衣と大きなおともだち	永井真衣	永井真衣のもふもふトーク番組。毎回ゲストさんを迎えてぶっちゃけトークをお送りしています。	http://1153friend.up.seesaa.net/image/podcast_artwork.jpg
38	http://0055808.NETSOLHOST.COM/Podcasts/podcast.xml	5 Minutes of BS on Photography	Bob Sachs	What motivates Bob Sachs as he creates images of the world around him?\n\nFind out as he discusses the featured images from his web site. He’ll let you in on all the facts that make up the photograph and a few that don’t.	http://0055808.NETSOLHOST.COM/Podcasts/bob5.jpg
39	Http://feeds.feedburner.com/wfodicks	WFOD: The Wheelbarrow Full of Dicks Internet Radio Program	Wheelbarrow Full of Dicks	The now world famous Wheelbarrow Full of Dicks Internet Radio Program constantly evolves with a wide range of topics and moods. You're never sure what you'll hear next.  A cavalcade of talk radio excellence for over a decade with quality celebrity interviews and social commentary.  Known for taking listeners along for a ride with interactive segments and games.  WFOD is a podcast unicorn.	https://wfodicks.podbean.com/mf/web/ci878d/wfodddfdfffggvvy.jpg
40	Http://ravenc-taouf.podomatic.com/rss2.xml	Dj_RavenC & DJ_Taouf's podcast	DJ_RavenC & DJ_Taouf		https://assets.podomatic.net/ts/c6/2e/b5/jf35bruz67819/1400x1400_5372830.png
41	http://12x50.wordpress.com/feed/	si-cut.db | Offices at Night [Volume II – remixes]	\N	12x50, digital free range products from England	\N
42	http://004.podOmatic.com/rss2.xml	JM VIBIN's Podcast	"004" - WWW.MYSPACE.COM/004MUSIC		https://004.podomatic.com/images/default/podcast-4-1400.png
43	http://04odedrajee.podomatic.com/rss2.xml	bob's Podcast	bob		https://04odedrajee.podomatic.com/images/default/podcast-3-3000.png
49	http://69.195.110.28/images/stories/audio/jmpicks/morrispicks.xml	Talk Radio For The Rest Of Us with Jared Morris	Jared Morris	WGMD Radio's Jared Morris "Jared Picks" podcast. 'best of' moments of the Jared Morris radio program handpicked by host Jared Morris. For more information on Jared goto www.wgmd.com and www.jared-morris.com	http://www.wgmd.com/images/jared-mlth.JPG
144	http://afripod.aodl.org/?feed=podcast	Africa Past & Present » Podcast Feed	Africa Past and Present	The Podcast about African History, Culture, and Politics	http://afripod.aodl.org/wp-content/uploads/2018/11/afripod-light_1400px.jpg
52	http://170.2022.m.edge-cdn.net/vdbrssvse_2022_1554	Commerzbank TV - ideasTV	ideasTV	IdeasTV ist das neue Fernsehformat der Derivateabteilung der Commerzbank.\nAktuelle Themen rund um das Thema Zertifikate und Optionsscheine, Markttrends, neue Produkte und interessante Handelsstrategien werden Ihnen aus erster Hand von Derivate-Experten vorgestellt und erklärt. \nIn regelmäßigen Abständen wird auch Jörg Krämer, Chefvolkswirt der Commerzbank, dem Moderator Thomas Timmermann zur makroökonomischen Lage an den internationalen Finanzmärkten Rede und Antwort stehen.	http://170.2022.m.edge-cdn.net/downloads/content/2022/673211_ideasTV_PODCAST_Logo_240614.jpg
53	http://170.2022.m.edge-cdn.net/vdbrssvsemp3_2022_1554	Commerzbank TV - ideasTV	ideasTV	IdeasTV ist das neue Fernsehformat der Derivateabteilung der Commerzbank.\nAktuelle Themen rund um das Thema Zertifikate und Optionsscheine, Markttrends, neue Produkte und interessante Handelsstrategien werden Ihnen aus erster Hand von Derivate-Experten vorgestellt und erklärt. \nIn regelmäßigen Abständen wird auch Jörg Krämer, Chefvolkswirt der Commerzbank, dem Moderator Thomas Timmermann zur makroökonomischen Lage an den internationalen Finanzmärkten Rede und Antwort stehen.	http://170.2022.m.edge-cdn.net/downloads/content/2022/673211_ideasTV_PODCAST_Logo_240614.jpg
54	http://1cor.jellycast.com/pod/podcast/1corcut.xml	One Crown Office Row Mini Podcast	One Crown Office Row	One Crown Office Row is one of the largest and most highly regarded barristers Chambers in England. It provides a wealth of free legal information (including details of recent cases and articles) through the resource section of their website at www.1cor.com. This also contains recorded versions of their talks, available as podcasts, which are normally accredited for solicitors or barristers under their relevant “Continuing Professional Development” (CPD) schemes. \n\nThey also run the unique Human Rights Update website at www.humanrights.org.uk which is also accessible through the main website. This contains over 900 commentaries on human rights cases, updated twice monthly, in a fully searchable format – all free of charge. This site has been recognised as one of the best free online legal services.\n\nChambers has regularly been listed by Legal Directories and journals as being among the country’s top 20. It currently has over 90 barristers, including 17 QCs, practising in London and in an Annexe in Brighton. \n\nIn London, Directories recognise it as having leading practitioners in a wide range of specialisms including clinical negligence, professional disciplinary work, personal injury, public and administrative law, public inquiries, human rights, healthcare, environmental law, matrimonial finance and property, professional negligence, costs and VAT and duties. Members also have successful practices in employment and equality law, immigration and asylum, multi-party actions, technology and construction and sports law.\n\nIn Brighton, Members practice in family and criminal law and in a wide range of civil law including landlord and tenant.	http://1cor.jellycast.com/pod/podcast/Picture%201.jpg
55	http://1onestop.byoaudio.com/rss/women_living_consciouly_telesummit.xml	Women Living Consciously Telesummit	Powerful You! Women's Network	47 Amazing Women\r\n16 Power-Packed Hours\r\nThese women have chosen to be more conscious in their lives.\r\nThey’ve shared their lessons and bared their souls\r\nin a collaborative anthology book for women,\r\nand now they’re coming together to share their\r\n\r\nInsights, Knowledge and Wisdom\r\nFor YOU!	https://1onestop.byoaudio.com/albumart/1002_itunes.1602747191.jpg
56	http://2-vs-2.com/podcast/podcast_feed.xml	2 vs. 2 Podcast	Grant K. Roberts & Joseph Caruso	Each week on the 2 vs. 2 Podcast, two game developers and two gamers talk about games.	http://2-vs-2.com/images/Logo_300.jpg
69	http://7school.seesaa.net/index20.rdf	ななちゅー放送せんたー	MAX過労＆コウイカ	MAXかろー・コウイカを中心に勝手に作ったpodcastを配信するサイトです！どうぞご気軽にコメントしていってくださ～い高校生だけでやってますよ。スゴくね？(笑)	\N
70	http://8111302.seesaa.net/index20.rdf	男子寮生妄想録	ERROR: NOT PERMITED METHOD: nickname 	\N	\N
71	http://7poundbag.com/feed/podcast/	Desk of Knowledge from 7poundbag.com	Desk of Knowledge from 7poundbag.com	For the Grabbag of Life	http://7poundbag.com/wp-content/uploads/powerpress/7pound-1400.jpg
145	http://aguirre-1.interliant.com/icons/JA2/rss.xml	Junior Achievement Evaluation Videos	JA Program	A Junior Achievement Evaluation involves several steps, and these videos were created to explain each one. 	http://aguirre-1.interliant.com/icons/JA2/JA.jpg
72	http://H2Opodcast.com/rss.xml	Water Environment - Lakes, Rivers, Oceans, Aquifers, Groundwater - Water (h2o) Environmental Issues: Conservation, Sustainability, Preservation, and Ecology	Joseph Puentes	Water Environment: Lakes, Rivers, Oceans, Seas, Groundwater, Wells - Water Conservation, Water Sustainability, Water Preservation, Water Ecology, and other H2O Environmental Issues\r\n\r\nContact info: Clean@h2opodcast.com or 206-984-3260; http://H2Opodcast.com	http://h2opodcast.com/images/h2o_300.jpg
73	http://IslamHouse.com/pc/420126	Ang pagpapaliwanag sa kahulugan ng Banal na Qur’an (Al-Menshawi)	\N	Ang pagpapaliwanag sa Banal na Qur’an sa wikang Tagalog	http://islamhouse.com/islamhouse-sq.jpg
75	http://a.dolimg.com/media/en-US/parksandresorts/podcasts/disneylandparis/disneyparks_disneylandparis_dutch.xml	Disney Parks and Resorts - Disneyland Paris	Disney Online	Find out what's new at Disneyland Paris!	http://a.dolimg.com/media/en-US/parksandresorts/podcasts/disneylandparis/podcast_icon.jpg
76	http://a.media.global.go.com/abccable/disneyxd/podcasts/skyrunners/rss-podcast.xml	Disney XD Skyrunners Podcast	Disney XD	Kelly Blatz talks about making the movie "Skyrunners" which premieres on Disney XD on Friday, November 27th 2009	http://a.media.global.go.com/abccable/disneyxd/podcasts/skyrunners/Skyrunners_Podcast1.png
77	http://a.media.global.go.com/abccable/disneychannel/podcasts/mackenziefalls/rss-podcast.xml	Mackenzie Falls	Mackenzie Falls	So much drama, So little time! Catch Mackenzie Falls mini-sodes where all you get are the BEST parts!	http://a.media.global.go.com/abccable/disneychannel/podcasts/mackenziefalls/image.jpg
78	http://a3mix.podcast.free.fr/xml/a3mix.xml	A3MiX d(-_-)b Podcast	A3MiX	Podcast electro regroupant le meilleur de la musique parisienne	http://a3mix.fr/img/podcast_image.jpg
79	http://aa-yaruobunko.x0.com/aa_yaruo_bunko_list.rdf	AA・やる夫文庫新刊一覧（EPUB）	AA・やる夫文庫	AA・やる夫文庫は，EPUB 形式の長編 AA・やる夫スレまとめサイトです．このサイトで配信されたまとめの中には本文，AA 対応フォント，画像が含まれており，一度ファイルをダウンロードすれば以後はオフラインで読むことができます．本サイトで配信されたまとめは iBooks(iOS)，Himawari Reader(Android)，Murasaki(Mac)，calibre v1.48.0(Windows/Mac/Linux) で正常に閲覧できることを確認しております．詳しくは http://aa-yaruobunko.x0.com/about を御覧ください．	http://aa-yaruobunko.x0.com/aa_yaruo_bunko.png
80	http://a59.g.akamai.net/f/59/9312/1m/ernstyoung.download.akamai.com/9312/rss/itsAlerts.xml	EY Cross-Border Taxation Alerts	Ernst & Young	The EY Cross-Border Taxation Podcast series brings you a weekly review of the latest US international tax-related developments.	http://a59.g.akamai.net/f/59/9312/1m/ernstyoung.download.akamai.com/9312/ncs/images/alerts2014.jpg
81	http://aarynblain.com/ab/Podcast/rss.xml	Aaryn Blain Podcast	Aaryn Blain	Welcome to Aaryn Blain’s world class podcast. Bringing you continuous mixes of the hottest upfront techno, minimal, electro, tech house and breaks. Activate your free subscription.	http://aarynblain.com/ab/Podcast/Podcast_files/Cartoon%20Blain.sharp600..jpg
131	http://adrien-adj.backdoorpodcasts.com/index.xml	Hype House	ADJ	The Best Tracks and Latest Releases of House/Electro/Progressive/Trance/Techno/Dance mixed by ADJ. Influences : Swedish House Mafia, Gregori Klosman, Tristan Garner, Bingo Players, Paride Saraceni, Fred Lilla, Sebjak, Avicii, Pete Tong, Michael Canitrot, Axwell, Ingrosso, Angello, Laidback Luke, Danny Wild, Anthony Watters, Fedde LeGrand, Francis Prève, Joachim Garraud, Mark Knight, Martin Solveig, David Guetta, Bob Sinclar, AN21, Max Vangeli, Dirty South, Antoine Clamaran, Armin Van Buuren, The Bloody Beetroots, Chris Kaeser, Dada Life and Many Others...\nUPDATE : PURE DEEP HOUSE from artists such as : Hot Since 82, Jamie Jones, Ten Walls, Maya Jane Coles, Dale Howard, Claptone, Bontan, Josh Butler, Notize, Dusky, Huxley, Tube & Berger, Amine Edge & DANCE, Noir, Haze, NTFO, Detroit Swindle, MK, KANT, KAASI, Chris Malinchak etc...	http://adrien-adj.backdoorpodcasts.com/uploads/items/adrien-adj/hype-house.jpg
132	http://abortmag.com/category/podcast/feed/	AbortCast: Interview Podcasts – ABORT Magazine	AbortCast	Canadian Counter-Culture	http://www.abortmag.com/abortpegs/abortfingerbanner.jpg
264	http://api.sr.se/api/rss/pod/8008	Olle och Gud	Sveriges Radio	Från 2009. Ett program om moraliska dilemman med prästen och kyrkoherden Olle Carlsson\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/3424/2938269_512_512.jpg?preset=api-itunes-presentation-image
133	http://adultstories.fastforward.libsynpro.com/rss	For Adults Only | Sexy Hot Stories Erotic from the Street	Monique Mistiere	HOT SEXY STORIES designed to GET YOU OFF.  This is audio sex at it's finest.  Get your tool for play too, use offer code DIRTY50 for 50 percent OFF, Free Shipping, Free Hot DVDs, and a Mystery Gift at www.adameve.com. Gotta use that code	http://static.libsyn.com/p/assets/a/6/c/3/a6c3c6fa2d1a6b84/Hot_Sex03.jpg
134	http://adventures.rnn.beta.libsynpro.com/rss	Adventures in Radio	Jim Widner	Adventures in Radio takes the listener back to early radio and the world of adventure in radio programs from the 1920s,1930s,1940s and 1950s.	http://static.libsyn.com/p/assets/0/4/d/1/04d1f7c25ecbc71f/adventuresinradio1400.jpg
136	http://ae.zawya.com/rss/itunes.cfm?rssid=E1209090997221122765512AD-9-12-2333-11	Zawya.com - Radio Podcasts	\N		\N
137	http://ae.zawya.com/rss/default.cfm?rssid=E1209090997221122765512AD-9-12-2333-11	Zawya.com - Radio Podcasts	\N		\N
138	http://adventurestories.rnn.beta.libsynpro.com/rss	Adventure Stories	Dennis Humphrey	Adventure Stories,hosted  Dennis Humphrey takes you back to the golden days of Radio by presenting the best Adventure Stories from Old Time Radio.	http://static.libsyn.com/p/assets/8/9/8/a/898a93288479237e/adventurealbart1400.jpg
139	http://affiliatecast.seesaa.net/index20.rdf	Affiliatecast(アフィリエイトキャスト)	affiliatecast	アフィリエイトやアドセンスについての"ポッドキャスト（ボイスブログ）"です！アフィリエイターに役立つノウハウとASP、ECサイトのインタビューなどもお伝えしていきます。	\N
140	http://afterbirthstories.com/abfeed/afterbirthstories.xml	Afterbirth Stories	Afterbirth Stories: Dani Klein Modisett	Afterbirth Stories is a collection of readings pulled from seven years of live Afterbirth performances in Los Angeles and New York.  The stories are original monologues written and performed by acclaimed writer/actor/comedian parents about the moment they knew their lives changed forever on becoming a parent. Although everyone's story is different, they're all candid, raw, and heart-felt.  They are intended for an adult audience.	http://afterbirthstories.com/abfeed/ab_logo_bevel3.jpg
141	http://adventuresintimespaceandmusic.phillipwserna.com/feed/podcast	Doctor Who: Adventures in Time, Space and Music	Dr. Lou (Dr. Louis Niebur) & Dr. Phill (Dr. Phillip W. Serna)	Hosted by Dr. Lou (Dr. Louis Niebur) & Dr. Phill (Dr. Phillip W. Serna), this podcast will sample music from the almost 50 year history of Doctor Who, discussing and debating the technical minutiae involved in the music, how it relates to the story, as well as explore the varied composers and musicians who have worked on the show.	http://adventuresintimespaceandmusic.phillipwserna.com/images/ATSM%20-%202%20Doctors%20-%20New%20iTunes%205.2011.jpg
142	http://agencysounds.com/dj-mixes/agency-podcasts.xml	Agency Sounds and BSP Radio	Agency Sounds DJs	Agency Sounds is proud the present "Pre-Game Fridays" from 4pm-8pm EST on BSP Radio (bsp.org). Every week we will have mixes from our roster (+ Guests!) showcasing their individual talents. Expect to hear the very best week after week from these seasoned vets.\n\nVisit our website for more information and booking info. Each file is labled by how they appeared in the episode so 1a would be first and then it would be 1b and so on. They appear backwards in itunes by release time.\n	http://agencysounds.com/dj-mixes/agency-sounds-logo.jpg
143	http://agi.jp/podcast/rss/agi_podcast.xml	AGI Presents 今夜のステージサイド	AIR GROOVE INDUSTRY	パーソナリティーのGGが、ピアニスト沢村繁のバーターとなり、様々なライブハウスの舞台袖からアーティストを交えて近況やライブ情報などを配信！	http://agi.jp/podcast/i_logo.jpg
265	http://api.sr.se/api/rss/pod/13923	Det svenska psyket	Sveriges Radio	Från 2011. En granskning av den svenska psykvården under 2000-talet. Vad har den inneburit för patienter och personal inom psykiatrin i Sverige?\r\nAnsvarig utgivare: Cecilia Bodström	https://static-cdn.sr.se/images/4000/2874533_512_512.jpg?preset=api-itunes-presentation-image
146	http://ahenfieonlineradio.com/podcast/akwantuo_mu_nsem/Akwantuo_Mu_Nsem.xml	Akwantuo Mu Nsem	Ahenfie Radio	Akwantuo Mu Nsem is an exclusive talk show hosted by Nana Kweku Boafo on issues that we face in Abroad with comments and contributions from listeners worldwide	http://ahenfieonlineradio.com/podcast/akwantuo_mu_nsem/banner.jpg
147	http://afripod.aodl.org/feed/	Africa Past & Present	Africa Past and Present	The Podcast about African History, Culture, and Politics	http://afripod.aodl.org/wp-content/uploads/2018/11/afripod-light_1400px.jpg
149	http://akotobko.seesaa.net/index20.rdf	A子とB子の『ABラジオ』！！	akoandbko	アートユニットA子とB子がお送りする『ABラジオ』毎週配信！！	http://akotobko.up.seesaa.net/image/podcast_artwork.jpg
150	http://akamai.paramountcomedy.com/podcast/robin_ince_uttershambles2.xml	Robin and Josie's Utter Shambles	Comedy Central	Robin Ince, Josie Long and guests discuss comedy, religion, Twitter, Facebook, science, evolution and comedy.	http://www.comedycentral.co.uk/gsp/images/utter_shambles-s4-300-x-300.jpg
151	http://albert-harari.backdoorpodcasts.com/index.xml	Harari Albert - Radio Electro-Show Selection	albertharari	Harari Albert - Radio Electro-Show Selection N en 1989 Genve (CH), Albert Harari est un Dj, remixeur et producteur suisse, ayant dbut sa carrire en Suisse au Carpe Diem Caf o il mixera pendant deux ans. Enchanant les dates en club, il aura loccasion de mixer aux cts de Djs de renom, tels que Laurent Wolf, producteur des tubes Saxo , Calinda , No Stress ou encore Wash My World , Get Far, producteur du tube Shining Star. , Arias ,coproducteur avec Tristan Garner du tube Give Love , ou encore Sbastien Bennett, crateur de House from Ibiza , lun des podcasts les plus couts au monde et aussi producteur des tubes Dancin et Week End. . En 2008 Albert cre un collectif de Dj avec 130 BPM avec qui il crera aussi son premier podcast qui, en moins de 2 semaines, se classera premier sur I-tunes Suisse. Ayant comme influence des Djs tels que Steve Angello, Axwell, Sebastian Ingrosso ou encore Arno Cost, Albert se lance prsent dans la production : quelques titres bientt lcoute ! Booking: bookingalbertharari@gmail.com	http://albert-harari.backdoorpodcasts.com/uploads/items/albert-harari/harari-albert-radio-electro-show-selection.png
152	http://aldenny.jellycast.com/podcast/feed/2	Al vs The Marathon	al denny	Two friends challenge me to an extreme athletical feat - to run the London Marathon!	https://aldenny.jellycast.com/files/malevich.black-square.jpg
153	http://aleks.phpwebhosting.com/aleks/fat/rss.xml	FAT: Facts and Technology	Aleks Oniszczak	Facts and Technology is a funny little show about gadgets gizmos, life and other wonderful things	http://aleks.phpwebhosting.com/aleks/fat/fat.jpg
154	http://alexandrebourkaib.free.fr/rssalexb.xml	Alex b's Podcast	Alex b	Portraits, enquêtes, journalisme, artwork...	http://alexandrebourkaib.free.fr/Podcast/alexb.jpg
155	http://alifewellwasted.com/episodes/episodes.xml	A Life Well Wasted	Robert Ashley	A Life Well Wasted is an internet radio show about videogames and the people who love them. Each episode focuses on a specific subject and employs interviews, music, writing, and fast-paced editing to create something unique in the podcasting space .	http://www.alifewellwasted.com/episodes/clover-controller_sm.jpg
157	http://al-muhajir.com/?feed=rss2	الموقع الرسمي للعلامة الشيخ عبدالحميد المهاجر	سماحة العلامة الشيخ عبدالحميد المهاجر		http://al-muhajir.com/wp-content/uploads/2011/09/iPhoneIcon_Big.png
158	http://alltone.ucsd.edu/podcast.xml	AllTone Radio on KSDT Podcast	T. Henthorn	UCSD Music and Contemporary Music on U.C. San Diego's radio station KSDT, every Tuesday from 8 to 10pm 	\N
159	http://allusgeeks.com/feed/podcast/	All Us Geeks	Jeff King & Jordan Steinhoff	We're here to give voice to your inner geek!	https://allusgeeks.com/wp-content/uploads/2015/01/AUG-1932x1932-GreenPurple.png
160	http://alohomora.seesaa.net/index20.rdf	のだめカンタービレとクラシック音楽	ＭＩＺ♪	のだめカンタービレとクラシック音楽配信・MP3ダウンロードDL☆ドラマ・映画公開情報サイトです。	http://alohomora.up.seesaa.net/image/podcast_artwork.jpg
116	http://abakuss.com/bc/bc_podcast.xml	Radio Incognitum	Jeff Morey	Podcast of DJ sets from radio incognitum. Genres include deep house, electronica, bass, minimal, techno, breaks. Subscribe and enjoy! Radio Incognitum is Jeff Morey	\N
266	http://api.sr.se/api/rss/pod/17155	Luuk & Lokko	Sveriges Radio	Från 2012. Kristian Luuk och Andres Lokkos liv och åsikter.\r\nAnsvarig utgivare: Daniel af Klintberg	https://static-cdn.sr.se/images/4296/1131fdb2-b534-447c-b38e-659fdefcd1e2.jpg?preset=api-itunes-presentation-image
177	http://alarms.hahaascomedyringtones.libsynpro.com/rss	! Ringtones by Hahaas Comedy Ringtones, Text Tones, Alerts & Alarms !	Hahaas Comedy Ringtones	Get FREE RINGTONES when you subscribe! Top Alarms from Hahaas Comedy Ringtones.  Search HAHAAS for free ringtone apps & 1000's more ringtones, alert tones & alarms.	http://static.libsyn.com/p/assets/8/c/c/3/8cc3f223fba4642b/2014ringtones-hahaas18.jpg
188	http://almanah.podfm.ru/rss/rss.xml	Альманах фантастики	PodFM.ru	"Альманах фантастики" — это проект некоммерческого журнала "Фантаскоп" для поклонников хорошей фантастики. Вашему вниманию представлен цикл многосерийных рассказов, как от признанных гуру русскоязычной фантастики, так и от новых авторов, которым проект дал возможность донести своё творчество до читателя.	http://file2.podfm.ru/18/181/1810/18104/images/lent_21247_big_45.jpg
189	http://alpinestarsinc.com/files/podcasts/default.xml	Alpinestars Video Podcast - One Goal. One Vision	Alpinestars	Alpinestars athletes	http://alpinestarsinc.com/files/podcasts/PCLogo.jpg
190	http://alltpaettkort.se/feed/podcast/	Allt på ett kort	Allt på ett kort	Spela tillsammans! Brädspel, kortspel & sällskapsspel	http://alltpaettkort.se/bilder/alltpaettkort.jpg
122	http://adammccune.com/podcastgen/feed.xml	Adam McCune's - Manch On the Street	Adam McCune	Award winning New Hampshire Union Leader columnist Adam McCune takes to the streets to find the stories that make New Hampshire, and its largest city tick.	http://adammccune.com/podcastgen/images/itunes_image.jpg
124	http://aboutlastnight.fakemustache.libsynpro.com/rss	About Last Night	About Last Night	Comedians Brad Williams and Adam Ray share crazy stories from their lives on the road. From sex, to sports, to booze, when a dwarf and a Jew come together the results are unpredictable but always entertaining.	http://static.libsyn.com/p/assets/6/f/1/1/6f116dda8e4dbb09/ALN_TEMP_COVER.png
267	http://api.sr.se/api/rss/pod/12402	Hansons Hörna	Sveriges Radio	Programmet uppdateras inte. Resultat, krönikor och de härligaste historierna från ishockeyns division 1.\r\nAnsvarig utgivare: Åsa Paborn	https://static-cdn.sr.se/images/2725/2401881_512_512.jpg?preset=api-itunes-presentation-image
268	http://api.videos.ndtv.com/apis/podcast/index/client_key/ndtv-podcast-5d35e3e34a92df17d11d54e0ff241e8b?shows=274&showfull=1&media_type=audio&extra_params=keywords,description	The Buck Stops Here	NDTV	A show with Barkha Dutt that brings you the big interviews, debates, all the elections news and of course, the very latest from our turbulent neighbours.	http://drop.ndtv.com/tvshows/show_274_1363591791.jpg
269	http://api.sr.se/api/rss/pod/6532	På nätet	Sveriges Radio	Programmet sändes 2009 och 2010.\r\nOm vårt sociala liv på internet.\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/3391/2395705_512_512.jpg?preset=api-itunes-presentation-image
270	http://api.sr.se/api/rss/pod/10471	Wretlind bland stjärnorna	Sveriges Radio	Radioveteranen Lennart Wretlind har grävt djupt i arkiven och presenterar intervjuer med några av musikvärldens största stjärnor.\r\nAnsvarig utgivare: Anna-Karin Larsson	https://static-cdn.sr.se/images/2347/1934831_512_512.jpg?preset=api-itunes-presentation-image
271	http://api.sr.se/api/rss/pod/15381	Jättestora frågor 	Sveriges Radio	Från 2011. Under några sommarveckor avhandlade Johanna Koljonen med gäster tio enorma frågeställningar.\r\nAnsvarig utgivare: Åsa Paborn	https://static-cdn.sr.se/images/4127/2394507_512_512.jpg?preset=api-itunes-presentation-image
272	http://api.sr.se/api/rss/pod/18825	Dramaklassiker	Sveriges Radio	Radioteater från förr.\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/4453/7cfd5df1-319c-4edd-9242-a7912e2064b9.jpg?preset=api-itunes-presentation-image
273	http://api.sr.se/api/rss/pod/7508	Odla med Stadsgrönt	Sveriges Radio	Från 2011. Ett odlingsprogram för stadsbor.\r\nAnsvarig utgivare: Cecilia Bodström	https://static-cdn.sr.se/images/3411/2954511_512_512.jpg?preset=api-itunes-presentation-image
274	http://api.sr.se/api/rss/pod/3991	Deluxe	Sveriges Radio	Sändes 2004-2008. P3 Humor presenterar Deluxe. \r\nAnsvarig utgivare: Tomas Granryd	https://static-cdn.sr.se/images/2053/2354475_512_512.jpg?preset=api-itunes-presentation-image
275	http://api.sr.se/api/rss/pod/9847	Sverige Berättar	Sveriges Radio	Sidan uppdateras inte. Lisa Syrén och lyssnares egna berättelser ur livet\r\nAnsvarig utgivare: Ulf Myrestam	https://static-cdn.sr.se/images/3706/1973644_512_512.jpg?preset=api-itunes-presentation-image
276	http://api.sr.se/api/rss/pod/3781	P4 Malmöhus	Sveriges Radio	Lokala nyheter, sport och kultur från Skåne.\r\nAnsvarig utgivare: Sandra Martinsson	https://static-cdn.sr.se/images/96/f4b9f6ef-b53c-4022-9e30-88ed80f25e2a.jpg?preset=api-itunes-presentation-image
277	http://api.sr.se/api/rss/pod/3774	P4 Göteborg	Sveriges Radio	Sveriges Radio P4 Göteborg ger dig lokala nyheter - i radion och på webben.\r\nAnsvarig utgivare: Mats Ottosson	https://static-cdn.sr.se/images/104/0904f0e7-53d3-4d22-b100-0c417b5db972.jpg?preset=api-itunes-presentation-image
278	http://api.sr.se/api/rss/pod/11465	Oförnuft och känsla	Sveriges Radio	Ett program om de enkla lösningarnas oändliga svårigheter.\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/3812/347416df-c9d9-441a-8928-14d24fb34bd6.jpg?preset=api-itunes-presentation-image
279	http://api.sr.se/api/rss/pod/15371	P4 Granskar	Sveriges Radio	Ett fördjupande samhällsprogram i Sveriges Radio P4\r\nAnsvarig utgivare: Ulla Walldén	https://static-cdn.sr.se/images/3375/0ddc35b3-47c7-4c9f-8bcb-2d14a4bb4ebb.jpg?preset=api-itunes-presentation-image
280	http://api.sr.se/api/rss/pod/10468	Prylarnas pris	Sveriges Radio	En serie som granskar hur vårt växande prylberg påverkar klimatet och miljön.\r\nAnsvarig utgivare: Olle Zachrison	https://static-cdn.sr.se/images/3737/7e2fefd1-89a7-413f-a123-da16966b8a1f.jpg?preset=api-itunes-presentation-image
281	http://api.sr.se/api/rss/pod/15382	Institutet	Sveriges Radio	Vetenskap, forskning och experiment\r\nAnsvarig utgivare: Caroline Pouron	https://static-cdn.sr.se/images/4131/e9478015-67ef-4e70-be75-20d0717538f3.jpg?preset=api-itunes-presentation-image
282	http://api.sr.se/api/rss/pod/8004	Sommarsamtalet	Sveriges Radio	En serie intervjuprogram där Martin Dyfverman och Katarina Hahr möter människor som berättar om sina liv och drivkrafter.\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/3494/2349952_512_512.jpg?preset=api-itunes-presentation-image
283	http://api.sr.se/api/rss/pod/8210	Sveriges Radio i Almedalen	Sveriges Radio	Politikerveckan i Almedalen, med alla partiledartalen i Visby. #SRAlmedalen\r\nAnsvarig utgivare: Olle Zachrison	https://static-cdn.sr.se/images/3227/f7356b49-7941-4e66-b9aa-eb0cc3d29b19.jpg?preset=api-itunes-presentation-image
284	http://api.sr.se/api/rss/pod/12208	Uggla i P4	Sveriges Radio	Programmet som hycklar och skiter i allt. Allt under ledning av Magnus Uggla.\r\nAnsvarig utgivare: Daniel af Klintberg	https://static-cdn.sr.se/images/3915/2748835_512_512.jpg?preset=api-itunes-presentation-image
285	http://api.sr.se/api/rss/pod/3952	Samtal pågår	Sveriges Radio	Programmet sänds inte längre. Rummet för den långa intervjun. Möt en person i ett tätt och nära samtal. En person och många gånger ett livsöde som förhoppningsvis du kan känna igen.Här hör du oftast de okända människorna - med en historia att berätta.\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/1054/2396090_512_512.jpg?preset=api-itunes-presentation-image
286	http://api.sr.se/api/rss/pod/3783	P4 Stockholm	Sveriges Radio	Stockholms största radiokanal med nyheter, sport och kultur i en härlig blandning.\r\nAnsvarig utgivare: Sofia Taavitsainen	https://static-cdn.sr.se/images/103/93751e41-25be-443e-aa50-3d65b67ae5ac.jpg?preset=api-itunes-presentation-image
287	http://api.sr.se/api/rss/pod/3989	Bildoktorn	Sveriges Radio	Problem med bilen? Då ringer du förstås till Bosse ”Bildoktorn” Andersson, som är beredd att besvara frågor om allt från nackstöd till förgasarstrul.\r\nAnsvarig utgivare: Peter Olsson	https://static-cdn.sr.se/images/2294/48ec8185-be67-49b8-822d-bdca4d24939e.jpg?preset=api-itunes-presentation-image
288	http://api.sr.se/api/rss/pod/6178	Arkivet Sjuhärad	Sveriges Radio	Här samlar vi på ljud som är värt att uppleva igen.\r\nAnsvarig utgivare: Lovisa Vasell	https://static-cdn.sr.se/images/3326/2409767_512_512.jpg?preset=api-itunes-presentation-image
289	http://api.sr.se/api/rss/pod/13027	Om P4 Väst	Sveriges Radio	Här får du veta med om vilka vi är som jobbar på P4 Väst.\r\nAnsvarig utgivare: Peter Sundblad	https://static-cdn.sr.se/images/content/sverigesradiologga.jpg?preset=api-itunes-presentation-image
211	http://andateala.com/blog/feed/podcast/	Digalocantando	Andateala.com	Chistes crueles	http://andateala.com/podcast/digalocantando_thumb.jpg
290	http://api.sr.se/api/rss/pod/5585	Kulturradion: Snittet	Sveriges Radio	Från 2010. För dig som tycker om när man rör sig på tvären mellan konstformerna. Här hör du om tendenser och händelser inom teater, konst, arkitektur, barnkultur, dans och opera.\r\nAnsvarig utgivare: Maria Götselius	https://static-cdn.sr.se/images/3049/2874518_512_512.jpg?preset=api-itunes-presentation-image
291	http://api.sr.se/api/rss/pod/14287	Förmiddag i P4 Jämtland	Sveriges Radio	Aktuell och underhållande förmiddag med gäster och mycket samspel med publiken.\r\n\r\n\r\n\r\nAnsvarig utgivare: Olof Ekerlid	https://static-cdn.sr.se/images/3336/c70a07a6-84f0-40b0-99df-025da34849cf.jpg?preset=api-itunes-presentation-image
292	http://api.sr.se/api/rss/pod/4911	Romane Paramichi	Sveriges Radio	Sagor och berättelser för barn på romani.\r\nRomane paramichi chavorenge pe romani chib.\r\nAnsvarig utgivare: Anne Sseruwagi	https://static-cdn.sr.se/images/3250/cbad5518-b813-4204-8c62-9977b3ac28aa.jpg?preset=api-itunes-presentation-image
293	http://api.sr.se/api/rss/pod/5191	Allvarligt talat	Sveriges Radio	Bengt Ohlsson och Liv Strömqvist svarar på publikens frågor.\r\nAnsvarig utgivare: Nina Glans	https://static-cdn.sr.se/images/3143/1caa817f-54c3-43ce-af05-3104045fe3a1.jpg?preset=api-itunes-presentation-image
294	http://api.sr.se/api/rss/pod/7145	Romanpriset	Sveriges Radio	Sveriges Radios Romanpris delas ut av en lyssnarjury under Litteraturveckan i P1 (23-29 april). Mer litteraturveckan hittar du i SR Play under P1 Kultur. \r\nAnsvarig utgivare: Marie Liljedahl	https://static-cdn.sr.se/images/499/476a0eca-5ba5-4b03-8224-465aa8000187.jpg?preset=api-itunes-presentation-image
295	http://api.sr.se/api/rss/pod/10469	Meänraatio  	Sveriges Radio	Rajatonta ja ihmisläheistä raatiota meänkielelä. / Gränslös och vardagsnära radio på meänkieli.\r\nAnsvarig utgivare: Patrik Boström	https://static-cdn.sr.se/images/1017/2599494f-8d98-4906-9e92-c7a72decc698.jpg?preset=api-itunes-presentation-image
296	http://api.sr.se/api/rss/pod/4891	Cirkus Kiev i P3	Sveriges Radio	Programmet sänder inte längre. För dig som gillar absurd humor, skruvad satir och blinkningar till populärkultur.\r\nAnsvarig utgivare: Åsa Paborn	https://static-cdn.sr.se/images/2640/1937610_512_512.jpg?preset=api-itunes-presentation-image
297	http://api.sr.se/api/rss/pod/9708	Vaken med P3 & P4	Sveriges Radio	Musik, tävlingar och samtal. Ett program för dig som är vaken, helt enkelt.\r\nAnsvarig utgivare: Sofia Taavitsainen	https://static-cdn.sr.se/images/2689/40b47bcf-1d1b-4fc4-be1c-9f37f9e2b9a6.jpg?preset=api-itunes-presentation-image
298	http://api.sr.se/api/rss/pod/5579	Bokcirkeln	Sveriges Radio	Programmet sänds från 2012 i Lundströms bokradio. Inbjudna gäster läser och  diskuterar böcker tillsammans.\r\nAnsvarig utgivare: Marie Liljedahl	https://static-cdn.sr.se/images/3349/54e0ae70-2b77-4951-bc42-a376b8c1cf7b.jpg?preset=api-itunes-presentation-image
299	http://api.sr.se/api/rss/pod/9985	P3 Kultur	Sveriges Radio	Programmet sändes 2010-2011. Nördorama med Johanna Koljonen. P3 Kultur analyserar och kärleksbombar hela samtidskulturen, hela vägen från superhjältar till samtidskonst, från romaner till rockklyschor.\r\nAnsvarig utgivare: Tomas Granryd	https://static-cdn.sr.se/images/3472/2395675_512_512.jpg?preset=api-itunes-presentation-image
300	http://api.sr.se/api/rss/pod/12396	P4 Premiär	Sveriges Radio	Programmet sänds inte längre. Det senaste inom populärkulturen\r\nAnsvarig utgivare: Dan Granlund	https://static-cdn.sr.se/images/2963/1957117_512_512.jpg?preset=api-itunes-presentation-image
301	http://api.sr.se/api/rss/pod/4897	Knattetimmens klipparkiv	Sveriges Radio	Sidan uppdateras inte. Malin Alfvén och Louise Hallin svarar på frågor om barn och föräldraskap\r\nAnsvarig utgivare: Andreas Miller	https://static-cdn.sr.se/images/3888/2527587_512_512.jpg?preset=api-itunes-presentation-image
302	http://api.sr.se/api/rss/pod/4892	Mammas Nya Kille	Sveriges Radio	Norrländsk humor när den är som bäst.\r\nAnsvarig utgivare: Matti Lilja 	https://static-cdn.sr.se/images/2399/cd2152f2-8c81-4fb4-8585-dcc114594f20.jpg?preset=api-itunes-presentation-image
303	http://api.sr.se/api/rss/pod/3821	Ekonomiekot	Sveriges Radio	Ekonomiekot är Ekots nyhetsprogram om senaste nytt i ekonomins värld.\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/178/af858666-b626-4e1a-bcda-f734fab87137.jpg?preset=api-itunes-presentation-image
304	http://api.sr.se/api/rss/pod/15451	P1 Specialprogram	Sveriges Radio	Här samlar vi extrasändningar och helgprogram från Sveriges Radio P1.\r\nAnsvarig utgivare: Nina Glans	https://static-cdn.sr.se/images/2702/9b253965-cfe8-4e67-93bd-928c8f85fd32.jpg?preset=api-itunes-presentation-image
305	http://api.sr.se/api/rss/pod/14029	Morgon i P4 Kristianstad	Sveriges Radio	Vi bjuder på nyheter, underhållning och en och annan överraskning. E-post: morgonen@sverigesradio.se\r\nAnsvarig utgivare: Petra Quiding	https://static-cdn.sr.se/images/3352/a0a1a682-2dd8-4e73-9134-5e51f9a72ddf.jpg?preset=api-itunes-presentation-image
306	http://api.sr.se/api/rss/pod/5187	Radio Romano	Sveriges Radio	Nyheter och program på romani\r\nAnsvarig utgivare: Anne Sseruwagi	https://static-cdn.sr.se/images/2122/3637846_1400_1400.jpg?preset=api-itunes-presentation-image
307	http://api.sr.se/api/rss/pod/7612	Teologiska rummet	Sveriges Radio	Teologiska frågor och debattämnen.\r\nAnsvarig utgivare: Mattias Hermansson	https://static-cdn.sr.se/images/3109/5e6eaf82-d269-4036-842e-bd1786153b1b.jpg?preset=api-itunes-presentation-image
308	http://api.sr.se/api/rss/pod/12202	P1-morgon	Sveriges Radio	Här hör du de senaste nyheterna, men vi nöjer oss inte där. Vi tar nyheterna djupare.\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/1650/d808a251-bbfa-49f7-8a74-fc2e7e88ba31.jpg?preset=api-itunes-presentation-image
309	http://api.sr.se/api/rss/pod/3961	P3 Populär	Sveriges Radio	Slutade sändas 2011. Programmet tog upp aktuella saker inom musik, mode och film.\r\nAnsvarig utgivare: Åsa Paborn	https://static-cdn.sr.se/images/2785/1937098_512_512.jpg?preset=api-itunes-presentation-image
310	http://api.sr.se/api/rss/pod/7534	P2-fågeln	Sveriges Radio	Pausfågeln. Lyssna på fåglar och samtal kring dem.\r\nAnsvarig utgivare: MARCUS SJÖHOLM	https://static-cdn.sr.se/images/3275/c7c7f26d-4582-45d0-93c3-2d20cbc35b5d.jpg?preset=api-itunes-presentation-image
311	http://api.sr.se/api/rss/pod/7509	Elfving möter	Sveriges Radio	Ulf Elfving möter kända svenskar.\r\nAnsvarig utgivare: Dan Granlund	https://static-cdn.sr.se/images/3164/ba2ee28f-7d84-4521-ac8e-8abb8c31bdec.jpg?preset=api-itunes-presentation-image
312	http://api.sr.se/api/rss/pod/5583	Biblioteket	Sveriges Radio	För dig som är intresserad av författande, författarskap och läsande. Här diskuteras ny som klassisk litteratur, lyrik, analyser, litteraturens historia och bortglömda böcker. \r\nAnsvarig utgivare: Elin Claeson Hirschfeldt	https://static-cdn.sr.se/images/1273/2327174_512_512.jpg?preset=api-itunes-presentation-image
313	http://api.sr.se/api/rss/pod/3984	Radiofynd	Sveriges Radio	Nio decennier av fantastisk radio att återupptäcka och minnas.\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/1602/3475755_1152_1152.jpg?preset=api-itunes-presentation-image
314	http://api.sr.se/api/rss/pod/17638	Carpe Fucking Diem 	Sveriges Radio	Programmet som fångar upp slutet på dagen och kastar ut den igen live, i en lite skruvad version.\r\nAnsvarig utgivare: Lotta Mossberg	https://static-cdn.sr.se/images/4335/2749506_512_512.jpg?preset=api-itunes-presentation-image
315	http://api.sr.se/api/rss/pod/5586	Kulturradion: K1/K2	Sveriges Radio	Slutade sändas 2012. En dokumentär väg in i kulturlivet. Programmet viker plats åt gestaltad radio, porträtt av levande och döda och ljudande essäer. Du som lyssnare blir bjuden på resor kors och tvärs genom länder, genrer, och konstnärligt brus.\r\nAnsvarig utgivare: Elin Claeson Hirschfeldt	https://static-cdn.sr.se/images/3050/2327227_512_512.jpg?preset=api-itunes-presentation-image
316	http://api.sr.se/api/rss/pod/4019	Klartext	Sveriges Radio	Nyheter på ett lite lugnare sätt och med enkla ord. \r\nVardagar 18.55-19.00 i P4 + 20.55-21.00 i P1. \r\nAnsvarig utgivare: Päivi Hjerp	https://static-cdn.sr.se/images/493/c80374c0-bd76-4cfb-875e-845a75700534.jpg?preset=api-itunes-presentation-image
317	http://api.sr.se/api/rss/pod/8226	P3 Planet	Sveriges Radio	Från 2012/2013. En reseguide som funkar som ett slags uppslagsverk där du som lyssnar kan få tips och hjälp med din planerade resa utomlands.\r\nAnsvarig utgivare: Åsa Paborn	https://static-cdn.sr.se/images/2948/2940164_512_512.jpg?preset=api-itunes-presentation-image
318	http://api.sr.se/api/rss/pod/4001	Sameradion & SVT Sápmi	Sveriges Radio	Ođđasat, dálkedieđut ja áigeguovdilis ságat, mánáid- ja nuoraidprográmmat, musihkka ja guoimmuheapmi/ Nyheter, väderrapporter och aktualiteter, barn- och ungdomsprogram samt musik och underhållning.\r\nAnsvarig utgivare: Ole-Isak Mienna	https://static-cdn.sr.se/images/2327/2447038_512_512.jpg?preset=api-itunes-presentation-image
319	http://api.sr.se/api/rss/pod/7565	P3 Nyheter Dokumentär	Sveriges Radio	Detta har hänt…\r\nAnsvarig utgivare: Caroline Lagergren	https://static-cdn.sr.se/images/1646/44b8351a-e28e-4bd7-8432-df68290ac020.jpg?preset=api-itunes-presentation-image
320	http://api.sr.se/api/rss/pod/4006	Radio Schweden	Sveriges Radio	Aktuelles aus Schweden\r\nAnsvarig utgivare: Olle Zachrison	https://static-cdn.sr.se/images/2108/3639464_1400_1400.jpg?preset=api-itunes-presentation-image
321	http://api.sr.se/api/rss/pod/6477	P2 Klassiskt arkiv	Sveriges Radio	Guldkorn ur Sveriges Radios arkiv. Olika program med material ur Sveriges Radios arkiv.\r\nAnsvarig utgivare: Elle-Kari Höjeberg	https://static-cdn.sr.se/images/3359/49c4a18e-c2ef-4da2-b1a7-ebac0a14c6ce.jpg?preset=api-itunes-presentation-image
322	http://api.sr.se/api/rss/pod/4000	Pang Prego	Sveriges Radio	Från 2009/2010. Humorprogram där varje program handlade om en lyssnare.\r\nAnsvarig utgivare: Anne Sseruwagi	https://static-cdn.sr.se/images/2782/2937970_512_512.jpg?preset=api-itunes-presentation-image
323	http://api.sr.se/api/rss/pod/3966	P3 Dokumentär	Sveriges Radio	Sveriges största podd om vår tids mest spännande händelser.\r\nAnsvarig utgivare: Caroline Lagergren	https://static-cdn.sr.se/images/2519/c3ffd637-4bf0-41a1-961f-28abdc067398.jpg?preset=api-itunes-presentation-image
324	http://api.sr.se/api/rss/pod/18342	Kulturdokumentären	Sveriges Radio	Sidan uppdateras inte. Korsbefruktningar mellan konst och samhälle. \r\nAnsvarig utgivare: Mattias Hermansson	https://static-cdn.sr.se/images/4384/3278718_1400_1400.jpg?preset=api-itunes-presentation-image
325	http://api.sr.se/api/rss/pod/14286	Eftermiddag i P4 Kristianstad	Sveriges Radio	Nyhetsfördjupning och eftermiddagsunderhållning. E-post: eftermiddag.kristianstad@sverigesradio.se \r\nAnsvarig utgivare: Petra Quiding	https://static-cdn.sr.se/images/2162/6d2bfbdf-478f-437e-9867-3c3d9a1c379f.jpg?preset=api-itunes-presentation-image
326	http://api.sr.se/api/rss/pod/11143	Klassikern	Sveriges Radio	Kulturredaktionen lyfter fram klassiska verk ur historien.\r\n\r\nAnsvarig utgivare: Katarina Dahlgren Svanevik	https://static-cdn.sr.se/images/3315/e195e587-ffee-4757-a2f9-e1ef1d335e74.jpg?preset=api-itunes-presentation-image
327	http://api.sr.se/api/rss/pod/3993	P3 Din Gata	Sveriges Radio	P3 Din Gata ger dig de bästa snackisarna och den bästa musiken. Från gatan - till gatan.\r\nAnsvarig utgivare: Anna Benker	https://static-cdn.sr.se/images/2576/9d9868ad-020a-4bfd-85da-aa12f2271ca9.jpg?preset=api-itunes-presentation-image
328	http://api.sr.se/api/rss/pod/3987	P4 Mötet	Sveriges Radio	Samtal med författare skådespelare dansare musiker tecknare fotografer och andra konstutövare\r\nAnsvarig utgivare: Lotta Mossberg	https://static-cdn.sr.se/images/745/2598310_512_512.jpg?preset=api-itunes-presentation-image
329	http://api.sr.se/api/rss/pod/3976	Vetenskapsradion Forum	Sveriges Radio	Sidan uppdateras inte. Om humanistisk och samhällsvetenskaplig forskning. Du som lyssnare får höra om forskning om människan som kultur- och samhällsvarelse.\r\nAnsvarig utgivare: Nina Glans	https://static-cdn.sr.se/images/1302/c0b42d24-570a-4444-b188-bb6d72a32ff3.jpg?preset=api-itunes-presentation-image
330	http://api.sr.se/api/rss/pod/3965	På minuten	Sveriges Radio	Hans Rosenfeldt och en pratglad panel som inte får tveka, upprepa sig eller lämna ämnet.\r\nAnsvarig utgivare: Daniel af Klintberg	https://static-cdn.sr.se/images/content/sverigesradiologga.jpg?preset=api-itunes-presentation-image
331	http://api.sr.se/api/rss/pod/4013	P1 Dokumentär	Sveriges Radio	Berättelser från verkligheten\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/909/77f00286-6cbd-4407-b95b-202ebc736e27.jpg?preset=api-itunes-presentation-image
332	http://api.sr.se/api/rss/pod/3988	Vetenskapsradions veckomagasin	Sveriges Radio	Nu går vi vidare med Vetenskapspodden på den här sändningstiden. Veckomagasinet slutar. Tack för alla år som lyssnare! (Januari 2020)\r\nAnsvarig utgivare: Alisa Bosnic	https://static-cdn.sr.se/images/415/567d747b-b6b5-4a5d-9d2b-06483bd91a23.jpg?preset=api-itunes-presentation-image
333	http://api.sr.se/api/rss/pod/9850	Karlavagnen	Sveriges Radio	Sveriges största samtalsrum. Ring 020-22 10 30.\r\nAnsvarig utgivare: Hanna Toll	https://static-cdn.sr.se/images/3117/fb916bd9-2da7-4130-90b5-164bd47c634b.jpg?preset=api-itunes-presentation-image
334	http://api.sr.se/api/rss/pod/10948	Sagor i Barnradion	Sveriges Radio	Sagor och serier för yngre barn varje vardag.\r\nAnsvarig utgivare: Hanna Toll	https://static-cdn.sr.se/images/2998/a3f4645d-f7c1-475f-a1de-4406d9df2e2e.jpg?preset=api-itunes-presentation-image
335	http://api.sr.se/api/rss/pod/4898	Sveriges Radio Finska	Sveriges Radio	Ruotsi suomeksi, silloin kun sinulle sopii. Live och poddar. Både på finska och svenska.\r\nAnsvarig utgivare: Anne Sseruwagi	https://static-cdn.sr.se/images/185/bce09053-09e1-4241-bdbc-a24107277d2d.jpg?preset=api-itunes-presentation-image
336	http://api.sr.se/api/rss/pod/13557	Ligga med P3	Sveriges Radio	En podd om sex – med Isabelle Hambe\r\nAnsvarig utgivare: Anna Benker	https://static-cdn.sr.se/images/3940/9a6bc337-b59f-49d0-842f-1b8b48a07c7a.jpg?preset=api-itunes-presentation-image
337	http://api.sr.se/api/rss/pod/11141	Zimmergren och Tengby	Sveriges Radio	Programmet sänds inte längre. \r\nAnsvarig utgivare: Nina Glans	https://static-cdn.sr.se/images/3076/bf261477-ea86-4891-91a4-92c6a59c5965.jpg?preset=api-itunes-presentation-image
338	http://api.sr.se/api/rss/pod/13716	Nordegren & Epstein i P1	Sveriges Radio	En aktuell och personlig talkshow måndag till torsdag med Louise Epstein och Thomas Nordegren.\r\nAnsvarig utgivare: Katarina Svanevik 	https://static-cdn.sr.se/images/4058/2c6793cb-5dfe-461a-95f1-e51346982357.jpg?preset=api-itunes-presentation-image
339	http://api.sr.se/api/rss/pod/12364	Radio Sweden Somali - Raadiyaha Iswiidhen	Sveriges Radio	Warar iyo Barnaamijyo Af Soomali ah\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/2172/bb7fb8ef-9873-4828-9dcb-34dd7f8ade37.jpg?preset=api-itunes-presentation-image
340	http://api.sr.se/api/rss/pod/4899	Sisuradio	Sveriges Radio	Ruotsi suomeksi, silloin kun sinulle sopii. Live och poddar. Både på finska och svenska.\r\nAnsvarig utgivare: Anne Sseruwagi	https://static-cdn.sr.se/images/185/bce09053-09e1-4241-bdbc-a24107277d2d.jpg?preset=api-itunes-presentation-image
341	http://api.sr.se/api/rss/pod/3795	Ekot	Sveriges Radio	Ekots stora dagliga nyhetssändningar. Nyheter och fördjupning – från Sverige och världen. Ansvarig utgivare: Klas Wolf-Watz\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/4540/7d9f6ad1-637c-4283-83b6-852716f0b837.jpg?preset=api-itunes-presentation-image
342	http://api.sr.se/api/rss/pod/18535	FotbollsArena Radiosporten	Sveriges Radio	Radiosportens fotbollspodd med Richard Henriksson.\r\nAnsvarig utgivare: Markus Boger	https://static-cdn.sr.se/images/4410/4d33c941-5527-4296-b8ac-64720992b29a.jpg?preset=api-itunes-presentation-image
343	http://api.sr.se/api/rss/pod/6615	Tendens – kortdokumentärer	Sveriges Radio	Korta dokumentärer från nutiden. Nära samtal om människors liv och idéer. \r\n\r\n\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/3381/802b7fad-49be-47f3-9372-1ee503ed7f25.jpg?preset=api-itunes-presentation-image
344	http://api.sr.se/api/rss/pod/5064	Catchy	Sveriges Radio	Musiikkiohjelma, jossa esitellään uudet ja vanhat hitit. /Musikprogram som spelar hits.\r\nAnsvarig utgivare: Anne Sseruwagi	https://static-cdn.sr.se/images/1319/1d0de8ff-ed3e-4ba6-8d36-2888797a4098.jpg?preset=api-itunes-presentation-image
345	http://api.sr.se/api/rss/pod/10470	Aamu	Sveriges Radio	Ajankohtainen ja viihteellinen aamushow, joka kertoo tärkeimmät uutiset ja puheenaiheet Ruotsista, Suomesta ja maailmalta.  \r\nAnsvarig utgivare: Anne Sseruwagi	https://static-cdn.sr.se/images/2500/1d8adfcb-5f9c-49b1-8e5f-14fd762ed9e0.jpg?preset=api-itunes-presentation-image
346	http://api.sr.se/api/rss/pod/4003	Publicerat	Sveriges Radio	Från 2013.\r\nAnsvarig utgivare: Anne Sseruwagi	https://static-cdn.sr.se/images/2792/2210013_512_512.jpg?preset=api-itunes-presentation-image
347	http://api.sr.se/api/rss/pod/3970	Plånboken	Sveriges Radio	Programmet som reder ut stora som små konsumentfrågor.\r\nAnsvarig utgivare: Nina Glans	https://static-cdn.sr.se/images/2778/d9052fa9-9ae6-4eac-8b64-d7f95a95959d.jpg?preset=api-itunes-presentation-image
348	http://api.sr.se/api/rss/pod/19144	Istid - Radiosportens hockeypodd	Sveriges Radio	I hockeypodden Istid ger vi dig de hetaste snackisarna från SHL, SDHL och hockeyallsvenskan samt intressanta gäster.\r\nAnsvarig utgivare: Markus Boger	https://static-cdn.sr.se/images/4468/ab1ae10b-2715-4aa6-8892-c7534c43e977.jpg?preset=api-itunes-presentation-image
349	http://api.sr.se/api/rss/pod/3955	Public Service	Sveriges Radio	Satir varje vecka i Godmorgon, världen!\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/2699/8377cfdf-098f-4351-9a07-ada35ffafb70.jpg?preset=api-itunes-presentation-image
350	http://api.sr.se/api/rss/pod/6230	Vetenskapsradion Klotet	Sveriges Radio	Vetenskapsradions internationella miljöprogram.\r\nAnsvarig utgivare: Alisa Bosnic	https://static-cdn.sr.se/images/3345/80ffa5fa-976b-4f13-ba9e-463d0b78ef88.jpg?preset=api-itunes-presentation-image
351	http://api.sr.se/api/rss/pod/4015	Kropp & Själ	Sveriges Radio	P1:s hälsojournalistiska program.\r\nAnsvarig utgivare: Nina Glans	https://static-cdn.sr.se/images/1272/efd51b02-ec34-4fda-9261-b6d7027930e8.jpg?preset=api-itunes-presentation-image
352	http://api.sr.se/api/rss/pod/3983	Radio Sweden Russian	Sveriges Radio	Новости по-русски из Швеции \r\nAnsvarig utgivare: Olle Zachrison	https://static-cdn.sr.se/images/2103/3547711_1152_1152.jpg?preset=api-itunes-presentation-image
353	http://api.sr.se/api/rss/pod/5504	Nordegren i P1	Sveriges Radio	Ersatt av Nordgren och Epstein i P1\r\nAnsvarig utgivare: Daniel af Klintberg	https://static-cdn.sr.se/images/3061/2874512_512_512.jpg?preset=api-itunes-presentation-image
354	http://api.sr.se/api/rss/pod/5324	Radiosportens nyhetssändningar	Sveriges Radio	Med det senaste i sportens värld.\r\nAnsvarig utgivare: Markus Boger	https://static-cdn.sr.se/images/2895/3668066_1400_1400.jpg?preset=api-itunes-presentation-image
355	http://api.sr.se/api/rss/pod/4888	Vid dagens slut	Sveriges Radio	Sidan uppdateras inte. Fem personliga minuter om livet \r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/1611/2333653_512_512.jpg?preset=api-itunes-presentation-image
356	http://api.sr.se/api/rss/pod/4023	Sommar & Vinter i P1	Sveriges Radio	Här hör du de personliga berättelserna som definierar vår tid. \r\n\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/2071/93595b27-4507-4c73-b3ff-85bd3f874efb.jpg?preset=api-itunes-presentation-image
357	http://api.sr.se/api/rss/pod/5063	Kino	Sveriges Radio	Veckomagasin om film, tv, dvd och internet. Detta är programmet för dig som vill nå längre och veta mer än genom de klassiska filmbevakningarna av biopremiärer. \r\nAnsvarig utgivare: Mattias Hermansson	https://static-cdn.sr.se/images/3051/3570430_1152_1152.jpg?preset=api-itunes-presentation-image
438	http://audio.achieveradio.com/podcast/anxiety-wellness.rss	Straight Talk About Mental Health with Karen Muranko	\N	Straight Talk About Mental Health features guests who will be discussing the many options available to assist people in achieving mental wellness. In addition to traditional treatments and techniques, Energy Psychology Techniques such as Cognitive Behavior Therapy, Emotional Freedom Technique and alternative treatments will be discussed. Karen and her guests wish to enlighten people living with a mental health disorder and offer support and encouragement.	\N
439	http://audio.darksideflow.com/firinfridaysfeed.xml	Darkside Flow and MC LA: Firin Fridays Podcast	Darkside Flow and MC LA	Darkside Flow and MC LA take you on a journey through Jungle/DNB music for two hours every week.  This podcast is originally broadcasted Fridays in Toronto from 9-11pm EST (2-4am GMT) on award nominated site Kunninmindz.com.  With international guests such as Skibadee and Shabba D as well as a stellar line-up of local guests, each show goes through the full spectrum of the music.	\N
440	http://audio.authorsaccess.com/podcasts/rss.xml	Authors Access	\N	Where authors get published and published authors get successful	\N
441	http://audio.dispatch.com/podcasts/FV/rss.xml	Faith & Values Podcast	The Columbus Dispatch	Religion news and insight from the Faith & Values reporters of The Columbus Dispatch.	http://audio.dispatch.com/podcasts/FV/Web_logo.jpg
442	http://audio.commonwealthclub.org/audio/podcast/climateone.xml	Climate One 	Climate One at The Commonwealth Club	Greg Dalton is changing the conversation on energy, economy and the environment by offering candid discussion from climate scientists, policymakers, activists, and concerned citizens. By gathering inspiring, credible, and compelling information, he provides an essential resource to change-makers looking to make a difference.	http://audio.commonwealthclub.org/audio/podcast/LargeTVBlue.jpg
443	http://audio.achieveradio.com/podcast/guyfinley.rss	Guy Finley's You Can Be Unstoppable	\N	The encouraging and accessible message of Guy Finley is one of the great bright lights in the world today. His concepts delve straight to the heart of our most urgent personal and social issues ­ relationships, fear, addiction, stress/anxiety, peace, happiness, freedom ­ and point the way to a higher life.	\N
444	http://audio.reelworship.com/grace_chapel/dircaster.php	Sermon Audio - Grace Chapel, Lexington, MA	sermons@grace.org (Grace Chapel)		http://audio.reelworship.com/grace_chapel/default.gif
445	http://audiodata.cricinfo.com/multimedia/andy_zaltzman.xml	Cricinfo: Andy Zaltzman's World Cricket Podcast	Andy Zaltzman	Comedian and writer Andy Zaltzman's audio show on current cricket	http://img.cricinfo.com/cricinfotalk/AndyZaltzman_600x600.jpg
446	http://audiodata.cricinfo.com/multimedia/Bowl_at_Boycs.xml	Cricinfo: Bowl at Boycs	Geoffrey Boycott	Geoffrey Boycott answers your questions on all things Cricket	http://img.cricinfo.com/cricinfotalk/BowlatBoycs_600x600.jpg
447	http://audiobiblepodcast.com/podcasts/podcast.cgi?name=mand;sched=nt;start=1/1/2010	ABP - Mandarin Chinese Bible - New Testament - January Start	audiobiblepodcast.com	Listen through the Mandarin Chinese New Testament twice in one year. Audio downloaded from from http://www.audiotreasure.com/mp3/Mandarin/. Podcast created by http://audiobiblepodcast.com.	http://audiobiblepodcast.com/images/Mandarin.jpg
448	http://authortalk.pearson.libsynpro.com/rss	Author Talk	Peachpit TV	Peachpit and New Riders publisher Nancy Aldrich-Ruenzel interviews authors about their latest works, techniques, and technologies.	http://static.libsyn.com/p/assets/d/9/0/5/d9055bf3d396f9ea/soapy.jpg
449	http://auto.sina.com.cn/746/2013/0129/41.xml	胖哥试车	新浪汽车	胖哥试车，新车试驾评测	http://i1.sinaimg.cn/qc/2013/0205/U4098P33DT20130205110606.jpg
450	http://automator.us/podcast/podcast.xml	AUTOMATOR.US	Nyhthawk Productions	AUTOMATOR.US is a website dedicated to provide information about the Automator application in Mac OS X.	http://automator.us/podcast/podcastimage.png
451	http://avemariaradio.net/kpmpodcast.xml	Ave Maria Radio: Kresta in the Afternoon	Al Kresta - Host	\N	https://avemariaradio.net/wp-content/uploads/2013/06/kresta1.jpg
452	http://avemariaradio.net/dipodcast.xml	Ave Maria Radio: The Doctor Is In	Dr. Ray Guarendi & Coleen Mast - Hosts	\N	https://avemariaradio.net/wp-content/uploads/2013/06/doctor_is_in.png
453	http://avidityfitness.net/wp-content/uploads/feed1.xml	The Fat Loss Troubleshooter Speaks	Leigh Peele	\N	http://www.leighpeele.com/images/avatar1.jpg
454	http://avsrule1126.tripod.com/fantasyindex.xml	Fantasy Football @ Undefeated Sports	Undefeated Sports	Advice for the 2006 Fantasy Football Season	\N
358	http://api.sr.se/api/rss/pod/3963	Filosofiska rummet	Sveriges Radio	Om klassiskt filosofiska ämnen såväl som vår tids mest brännande etiska, existentiella & politiska dilemman.\r\nAnsvarig utgivare: Marie Liljedahl	https://static-cdn.sr.se/images/793/4bce2a0c-2bd1-4401-ae35-d43861b36437.jpg?preset=api-itunes-presentation-image
359	http://api.sr.se/api/rss/pod/4886	Radiokorrespondenterna	Sveriges Radio	Följ med Sveriges Radios korrespondenter ut i världen och hör om ämnen som bränner och diskuteras där de har sin vardag.\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/2946/575c0b88-60b6-4ab4-b47f-20f9e4113621.jpg?preset=api-itunes-presentation-image
360	http://api.sr.se/api/rss/pod/3982	Arkiv: Lantz i P1 och P4	Sveriges Radio	Från 2010. Radioprofilen Annika Lantz bjuder på ett brett spektrum av gäster och en verklighet filtrerad av programledaren själv.\r\nAnsvarig utgivare: Christina Gustafsson	https://static-cdn.sr.se/images/2822/2395533_512_512.jpg?preset=api-itunes-presentation-image
361	http://api.sr.se/api/rss/pod/4017	Vetenskapsradion På djupet	Sveriges Radio	Vi går på djupet i forskningen.\r\nAnsvarig utgivare: Alisa Bosnic	https://static-cdn.sr.se/images/412/0626e077-2198-4bf4-9100-6bf664e7001a.jpg?preset=api-itunes-presentation-image
362	http://api.sr.se/api/rss/pod/18294	P3 Soul	Sveriges Radio	Mats Nileskär spelar musik och gör exklusiva intervjuer med soul- och hiphopartister världen över.\r\nAnsvarig utgivare: Anna Stenberg	https://static-cdn.sr.se/images/2680/12cabe77-e4fc-4e55-8623-200240299e3f.jpg?preset=api-itunes-presentation-image
363	http://api.sr.se/api/rss/pod/11140	Humorn i P3	Sveriges Radio	I Humorn i P3: Scenen följer vi vännerna och kollegorna Tora och Elvira som kämpande komiker i Umeå.\r\nAnsvarig utgivare: Matti Lilja	https://static-cdn.sr.se/images/3389/698d204a-3e6d-452e-a7aa-ae48b4889229.jpg?preset=api-itunes-presentation-image
364	http://api.sr.se/api/rss/pod/4901	Radio Sweden	Sveriges Radio	Your best source of news from Sweden\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/2054/350495d8-9f8f-4bdf-a5cd-18e08b161d97.jpg?preset=api-itunes-presentation-image
365	http://api.sr.se/api/rss/pod/3962	Radio Sweden Farsi/Dari رادیو سوئد / رادیوی سویدن	Sveriges Radio	بخش فارسی رادیو سوئد | بخش دری رادیوی سویدن\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/2493/6b7cb62e-e94b-48d7-8828-f3c034c57147.jpg?preset=api-itunes-presentation-image
366	http://api.sr.se/api/rss/pod/5581	Kulturnytt i P1	Sveriges Radio	Nyhetssändning från kulturredaktionen P1, med reportage, nyheter och recensioner.\r\nAnsvarig utgivare: Katarina Dahlgren Svanevik	https://static-cdn.sr.se/images/478/395900e5-d243-498e-9f12-eea2bd9ccaf4.jpg?preset=api-itunes-presentation-image
367	http://api.sr.se/api/rss/pod/3951	Medierna	Sveriges Radio	Granskar medier och journalistik. Går bakom veckans rubriker och spanar i framtidens medielandskap.\r\nAnsvarig utgivare: Nina Glans	https://static-cdn.sr.se/images/2795/6f025b41-6db1-4060-80a7-41ef3d78cc1a.jpg?preset=api-itunes-presentation-image
368	http://api.sr.se/api/rss/pod/14423	Svensktoppen 	Sveriges Radio	Listan som är en av de mest betydelsefulla måttstockarna av svensk musik.\r\nAnsvarig utgivare: Katarina Svanevik 	https://static-cdn.sr.se/images/2023/468b2f20-e2c3-43ce-9d6b-e63f13e10017.jpg?preset=api-itunes-presentation-image
369	http://api.sr.se/api/rss/pod/4895	Verkligheten i P3	Sveriges Radio	Det finns ett före och ett efter. En människa, en story.\r\nAnsvarig utgivare: Caroline Pouron	https://static-cdn.sr.se/images/3052/9f978572-ed62-4f0f-a6b4-9e7506cb6c44.jpg?preset=api-itunes-presentation-image
370	http://api.sr.se/api/rss/pod/17013	PP3 	Sveriges Radio	Dagsaktuell talkshow om den popkulturella världen, med Linnéa Wikblad, Sara Kinberg och Adrian Boberg.\r\nAnsvarig utgivare: Caroline Lagergren	https://static-cdn.sr.se/images/4283/966e138a-5bc4-40b5-b9b2-43bb1c9e2e77.jpg?preset=api-itunes-presentation-image
371	http://api.sr.se/api/rss/pod/6616	P4 Extra 	Sveriges Radio	En mix av de hetaste personerna och nyheter från jordens alla hörn. \r\nAnsvarig utgivare: Sofia Taavitsainen	https://static-cdn.sr.se/images/2151/1439c557-fc72-416f-81f8-083b70c6d634.jpg?preset=api-itunes-presentation-image
372	http://api.sr.se/api/rss/pod/4896	P4 Dokumentär	Sveriges Radio	Berättelser som berör\r\n\r\nAnsvarig utgivare: Alisa Bosnic	https://static-cdn.sr.se/images/3103/acaa84ad-4fb2-47a7-9720-41fbf3ff450a.jpg?preset=api-itunes-presentation-image
373	http://api.sr.se/api/rss/pod/4021	Studio Ett	Sveriges Radio	Fördjupar dagens stora händelser i Sverige och världen.\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/1637/ea94db5e-390c-40de-99ff-47a9b00ca1d5.jpg?preset=api-itunes-presentation-image
374	http://api.sr.se/api/rss/pod/3953	Ekots lördagsintervju	Sveriges Radio	Intervju, analys och fördjupning av veckans stora politiska händelser.\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/3071/60e3451e-b34e-4145-8963-98099d24005f.jpg?preset=api-itunes-presentation-image
375	http://api.sr.se/api/rss/pod/3977	Radio Sweden Kurdish - ڕادیۆی سوید - Radyoya Swêdê 	Sveriges Radio	بەشی کوردیی ڕادیۆی سوید\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/2200/0827765c-eeb1-4cde-872a-a7a049104549.jpg?preset=api-itunes-presentation-image
376	http://api.sr.se/api/rss/pod/4007	Spanarna	Sveriges Radio	Tre skarpsynta personligheter försöker avläsa trender i vår vardag och ge oss sina framtidsvisioner.\r\nAnsvarig utgivare: Katarina Svanevik 	https://static-cdn.sr.se/images/516/52ce40a8-3681-4fcf-b61b-125935a415f9.jpg?preset=api-itunes-presentation-image
377	http://applemania.podfm.ru/rss/rss.xml	"На дне!" — развлекательное шоу о играх и кино	Влад Филатов и Сергей Болисов	Еженедельное развлекательное шоу "На дне!" - это море позитива и самые актуальные темы индустрии видеоигр и кино. В качестве ведущих выступают создатели шоу "СТАРТУЕМ!" на GSTV: Кирилл Улезко, Павел Сергазиев и Влад Филатов.  Контактный email: filatovvlad@icloud.com  Материальная помощь проекту: ссылка	http://file2.podfm.ru/10/107/1077/10771/images/lent_12166_big_55.jpg
378	http://api.sr.se/api/rss/pod/9946	Tankesmedjan	Sveriges Radio	Sylvass satir om nyheter, politik och en hel del kändisar.\r\nAnsvarig utgivare: Caroline Pouron	https://static-cdn.sr.se/images/3718/42a72111-c3af-4fd3-b6ba-1580311e7b9f.jpg?preset=api-itunes-presentation-image
379	http://api.sr.se/api/rss/pod/9135	Radiopsykologen	Sveriges Radio	Psykologen Lasse Övling möter lyssnare i ett terapeutiskt samtal. \r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/3637/26cd61e2-9e8c-4fb9-ba61-0c2ba2c6fc32.jpg?preset=api-itunes-presentation-image
455	http://az29521.vo.msecnd.net/cdn/onelife_podcasts.xml	One Life			http://az29521.vo.msecnd.net/cdn/ONE LIFE_ITUNES_600x600.jpg
380	http://api.sr.se/api/rss/pod/3958	Godmorgon världen	Sveriges Radio	P1:s veckomagasin om Sverige och världen – politik och trender, satir och analyser.\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/438/799b79c6-1932-4367-9e0b-d83d8503118d.jpg?preset=api-itunes-presentation-image
381	http://api.sr.se/api/rss/pod/4012	Språket	Sveriges Radio	Hur språk används och förändras. Här kan du som lyssnare ställa dina frågor om språk.\r\nAnsvarig utgivare: Hanna Toll	https://static-cdn.sr.se/images/411/0ded6dcf-4edc-4bbe-a9c0-7e77d5b0832a.jpg?preset=api-itunes-presentation-image
382	http://api.sr.se/api/rss/pod/6688	Ring P1 - 020-22 10 10	Sveriges Radio	Ring oss på 020-22 10 10 och tyck till!\r\nAnsvarig utgivare: Beror på sändningsort, se resp. avsnitt	https://static-cdn.sr.se/images/1120/2b135da2-728f-493c-a109-c0f91137aeae.jpg?preset=api-itunes-presentation-image
383	http://api.sr.se/api/rss/pod/6177	Brunchrapporten 	Sveriges Radio	Sändes 2009-2011. Osaklig och partisk radio med Henrik Torehammar\r\nAnsvarig utgivare: Ylva M Andersson	https://static-cdn.sr.se/images/3182/1936987_512_512.jpg?preset=api-itunes-presentation-image
384	http://appropriateomnivore.com/podcasts/appomnivore.xml	The Appropriate Omnivore with Aaron Zober	The Appropriate Omnivore	The Appropriate Omnivore is hosted by environmentalist and meat lover Aaron Zober. Breaking the myth that eating meat is bad for the environment, Aaron talks about how meat, as well as the other food groups, are best when they're local, organic, and sustainable.<br />\n<br />\nEach week, Aaron brings on a guest to share experience and wisdom about what's good to eat. Think you know what foods are good for you and the planet?  What you hear may surprise you and get you on a shopping spree for a new diet.<br />\n<br />\nThe Appropriate Omnivore<br />\nhttp://www.AppropriateOmnivore.com	http://appropriateomnivore.com/podcasts/appomnivore.xml/TAO-Logo_2048-1500px.jpg
385	http://api.sr.se/api/rss/pod/3957	Tankar för dagen	Sveriges Radio	En stunds eftertanke mitt i morgonens nyhetsflöde. \r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/1165/2d142482-7a0d-46eb-b012-c7eafcf68aff.jpg?preset=api-itunes-presentation-image
386	http://api.sr.se/api/rss/pod/4890	Vetenskapsradion Nyheter	Sveriges Radio	Vetenskapsnyheter från alla tänkbara forskningsområden. Här får du som lyssnare ofta höra nyheten innan den blir uppmärksammad av övriga media. Sänds i P1.\r\nAnsvarig utgivare: Alisa Bosnic	https://static-cdn.sr.se/images/406/58ca300d-9636-4192-b532-6a4962f15c6c.jpg?preset=api-itunes-presentation-image
387	http://api.sr.se/api/rss/pod/8079	Lilla Al-Fadji	Sveriges Radio	Humor i P3 med Lilla Al-Fadji.\r\nAnsvarig utgivare: Cajsa Lindberg	https://static-cdn.sr.se/images/3473/0a0e3109-141c-49d0-8220-b9c74324024b.jpg?preset=api-itunes-presentation-image
388	http://api.sr.se/api/rss/pod/4022	Barnen	Sveriges Radio	Programmet sänder inte längre. I detta program fick barnen plats i samhällsdebatten och du som lyssnare fick höra livet ur deras perspektiv för att se hela samhället tydligt och skarpt.\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/787/a0825522-82d4-4d8d-afa4-67cf974173ca.jpg?preset=api-itunes-presentation-image
389	http://api.sr.se/api/rss/pod/3994	Odla med P1	Sveriges Radio	För dig som är fritidsodlare och som vill gräva lite djupare i kompost och rabatter för att lära dig mer om odling. Här får du experttips, goda råd och en inblick i odlandets olika trender och möjligheter.\r\nAnsvarig utgivare: Alisa Bosnic	https://static-cdn.sr.se/images/1667/a4dff883-6ffe-4126-9cff-fe9a9eb354d7.jpg?preset=api-itunes-presentation-image
390	http://archief.gkv-eindhoven.nl/archief/podcast/preken	Preken gehouden in de GKv Eindhoven	GKv Eindhoven	Gearchiveerde opnamen van bijeenkomsten uit de Jacobuskerk te Eindhoven.	http://archief.gkv-eindhoven.nl/archief-server2/img/podcast_jacobuskerk-gkv-eindhoven.jpg
391	http://api.sr.se/api/rss/pod/4011	Christer	Sveriges Radio	Christer är din vän i etern. Här ryms moraltest av makthavare, livets stora och små frågor och inte minst - dina berättelser. I Relationsrådet får du hjälp genom kärleksdjungeln och i Fredagsflörten skapas varje vecka ett nytt radiopar. \r\nAnsvarig utgivare: Ylva M Andersson	https://static-cdn.sr.se/images/3130/2968021_512_512.jpg?preset=api-itunes-presentation-image
392	http://arapahoephysicsb.blogspot.com/feeds/posts/default	Smith's AP Physics B @ Arapahoe	\N	\N	\N
393	http://api.sr.se/api/rss/pod/4887	Stil	Sveriges Radio	Gräver djupt i det ytliga.\r\nAnsvarig utgivare: Nina Glans	https://static-cdn.sr.se/images/2794/e0a5c741-6576-4c03-9934-d59e17f495ae.jpg?preset=api-itunes-presentation-image
394	http://api.sr.se/api/rss/pod/4893	Morgonpasset i P3	Sveriges Radio	Kom in i värmen! Varje morgon i P3 är en fartfylld resa, full av intryck.\r\nAnsvarig utgivare: Caroline Lagergren 	https://static-cdn.sr.se/images/2024/caf2b65e-d6a4-4b66-a2dc-4d6bd8a5cd16.jpg?preset=api-itunes-presentation-image
395	http://archive.integrationworks.com/feed5.xml	Bible Answer Man Podcast with Hank Hanegraaff	Hank Hanegraaff	The Podcast of the Bible Answer Man broadcast	https://www.equip.org/wp-content/uploads/2019/10/BAM-PODCAST-with-HHH.jpg
396	http://annebachrach.hipcast.com/rss/the_accountability_coach.xml	Wheel of Life Podcast: Business|Productivity|Accountability	Anne Bachrach	Create your personal Wheel of Life, for helping you find balance in everyday life. This powerful tool puts your life in perspective and helps you set goals around creating total life balance and enhancing your quality of life.\r\n\r\nProven Business Success Principles and Systems for Working Less, Making More Money, and Enjoying Better Work Life Balance.\r\n\r\nYou will discover proven and practical ideas you can immediately apply in all areas of your business and personal life so you can achieve your goals in the time frames you desire. \r\n\r\nWouldn’t it be great if our ‘good intentions’ worked the way that we think they should?  Not even enthusiasm guarantees positive results. There’s often a wide gap between our intentions and our actions.  We fail to take the action necessary to be in alignment with our good intentions. This can be very frustrating.  \r\n\r\nGood intentions don’t magically lead to good results. They are a start; however, they are unfortunately not enough. This is just the truth!  We all can use a little accountability in our life to help us stay focused so we can achieve all our goals in the time frames we desire.  \r\n\r\nAnne Bachrach is author of Excuses Don't Count; Results Rule!, Live Life with No Regrets; How the Choices we Make Impact our Lives, No Excuses, and The Work Life Balance Emergency Kit.  Listen to the Podcasts and you can create the kind of life you have always dreamed of having.  Go to www.AccountabilityCoach.com/landing today and take advantage of 3 Free gifts that you can immediately use to help you achieve your professional and personal goals.\r\n\r\nVisit www.AccountabilityCoach.com and receive 10% off all high-value products and services along with many complimentary resources and tools available to you under the FREE Silver Membership.  You have access to tools like the Quality of Life Enhancer™ Exercise, a Wheel of Life exercise for helping you find balance in everyday life, assessments, articles, and so much more. \r\n\r\nSubscribe to the high-content Blog and receive valuable information.  https://www.accountabilitycoach.com/blog/	https://annebachrach.hipcast.com/albumart/1001_itunes_1603052931.jpg
397	http://api.sr.se/api/rss/pod/4008	Naturmorgon	Sveriges Radio	Tar upp alla aspekter av naturen, från njutning till forskning. \r\nAnsvarig utgivare: Marcus Sjöholm	https://static-cdn.sr.se/images/1027/45e83b47-d9a5-4b1d-9481-4b6edb6da93e.jpg?preset=api-itunes-presentation-image
398	http://api.sr.se/api/rss/pod/4020	Vetenskapsradion Historia	Sveriges Radio	Vi är där historien är.\r\nAnsvarig utgivare: Nina Glans	https://static-cdn.sr.se/images/407/573c74bb-aec7-4ab8-99a0-180cb2538dd4.jpg?preset=api-itunes-presentation-image
399	http://api.sr.se/api/rss/pod/8749	Ekonomiekot Extra	Sveriges Radio	Vad hände i ekonomivärlden i veckan? Programledare Hanna Malmodin.\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/3626/4a9c60cf-b4b2-4907-8dea-3c60226f8838.jpg?preset=api-itunes-presentation-image
400	http://archive.org/services/collection-rss.php?mediatype=audio	Internet Archive - Mediatype: audio	\N	The most recent additions to the Internet Archive collections.  This RSS feed is generated dynamically	\N
401	http://api.sr.se/api/rss/pod/3967	Konflikt	Sveriges Radio	Konflikt är Sveriges Radios fördjupande utrikesmagasin. Vi vill knyta ihop världspolitik och svensk vardag.\r\nAnsvarig utgivare: Klas Wolf-Watz	https://static-cdn.sr.se/images/1300/5ac4a3db-727c-405a-82f4-d432a6b43a9b.jpg?preset=api-itunes-presentation-image
402	http://api.sr.se/api/rss/pod/3973	Människor och tro	Sveriges Radio	Livsåskådningsprogrammet i P1 om religion, identitet och politik.\r\n\r\nAnsvarig utgivare: Louise Welander	https://static-cdn.sr.se/images/416/e941be64-b131-49a4-b204-9e24cb288153.jpg?preset=api-itunes-presentation-image
403	http://api.sr.se/api/rss/pod/4009	Meny 	Sveriges Radio	Sveriges Radios matprogram som tittar djupt i grytorna. \r\nAnsvarig utgivare: Nina Glans	https://static-cdn.sr.se/images/950/63f65890-c4ba-45dc-8039-5272ae4f07f0.jpg?preset=api-itunes-presentation-image
404	http://archive.wort-fm.org/xml/mf.xml	wort - Mel & Floyd	\N	Mel & Floyd	\N
405	http://ardentatheist.com/feeds/ardent.xml	Ardent Atheist with Emery Emery	Ardent Atheist with Emery Emery	\nArdent Atheists Emery Emery and Heather Henderson talk with comedians, actors and friends about atheism, deism and the effects of religion on us all. Guests of the show are a mix of atheists, agnostics, deists, scientists, humanists and the occasional god-loving, scripture-quoting crusader. Discussions are deeply impassioned, mostly respectful and always funny.\n\nArdent Atheist - Where Reason Reigns Supreme!\nListen LIVE Wednesdays 7-8 PM PST On http://ardentatheist.com.\n	http://ardentatheist.com/feeds/images/ardent_atheist_logo.jpg
406	http://areadownloads.autodesk.com/wdm/3dsmax/itunes/3dsmax_itunes_rss.xml	3ds Max Learning Channel	Autodesk	The official learning channel for Autodesk® 3ds Max® software, a comprehensive 3D modeling, animation, rendering, and compositing solution for games, film, and motion graphics artists. The Autodesk® 3ds Max® Learning Channel provides tutorials of all levels to help you learn Autodesk® 3ds Max®.	http://areadownloads.autodesk.com/wdm/3dsmax/itunes/3dsmax_itunes.jpg
407	http://areadownloads.autodesk.com/wdm/smoke/itunes/slc_itunes_rss.xml	Smoke Learning Channel	Autodesk	The official learning channel for Autodesk® Smoke® software, the all-in-one solution that connects editing and visual effects. The Autodesk® Smoke® Learning Channel provides tutorials of all levels to help you learn Autodesk® Smoke®.	http://areadownloads.autodesk.com/wdm/smoke/slc_itunes_rss.jpg
408	http://ardrone-podcast.de/feed/episodes	AR.Drone Podcast	AR.Drone Podcast	Ein Video-Podcast rund um die AR.Drone.	http://ardrone-podcast.de/wp-content/cover/podcast-logo-1500.png
135	http://adventuresinirrationality.libsyn.com/rss	Adventures in Irrationality	Jeremy Tobin and Eric Young	A weekly podcast in which Jeremy Tobin and Eric Young explore a world devoid of sense.	http://static.libsyn.com/p/assets/4/e/6/7/4e67695b63fffe68/Android_Large_Icon_copy.png
409	http://arguments.podbean.com/category/itunes-espanol/feed/	Arguments Pool Podcast	hbqfxl	Herbie and Sway go around the league in the Arguments Pool	//pbcdn1.podbean.com/imglogo/image-logo/5971466/podcast_image_5D51AEDE-23F3-4ADD-B5CF-81A9F1BB8F0A.jpg
410	http://argotpod.free.fr/argotpod.xml	ArgotPod - Le français non censuré !	Christophe	Ce Podcast est dédié à l'argot français aux langages familiers et courants ainsi qu'aux mots vulgaires. Réalisé pour les personnes qui souhaitent apprendre et approfondir leur connaissances de la langue française. Attention contenu trés explicite.\r\n\r\nargotpod@gmail.com\r\nhttp://argotpod.free.fr/\r\n	http://argotpod.free.fr/argotpodlogo.jpg
411	http://areadownloads.autodesk.com/oc/itunes/smokesignals_itunes_rss2.xml	Smoke Signals	Autodesk	An insider's look at Autodesk® Smoke® 2013 software, the all-in-one solution that connects editing and visual effects. Watch news, tips & tricks, interviews, and useful links, direct from Autodesk.	http://areadownloads.autodesk.com/oc/itunes/SmokeSignals_CoverArt.jpg
412	http://areadownloads.autodesk.com/wdm/maya/itunes/maya_itunes_rss.xml	Maya Learning Channel	Autodesk	The official learning channel for Autodesk® Maya® software, the 3D animation software offers a comprehensive creative feature set for 3D computer animation, modeling, simulation, rendering, and compositing on a highly extensible production platform. The Autodesk® Maya® Learning Channel provides tutorials of all levels to help you learn Autodesk® Maya®.	http://areadownloads.autodesk.com/wdm/maya/itunes/maya_itunes.jpg
413	http://arstarcast.org/?feed=podcast	Ann Richards StarCast	Ann Richards StarCast	Voices from the Stars	http://arstarcast.org/wp-content/uploads/powerpress/ARS---logo-with-circle-1400.jpg
414	http://army.podfm.ru/rss/rss.xml	Армейские Воспоминания	PodFM.ru	"Армейские Воспоминания" — это не просто воспоминания, это первый авторский подкаст об армии.  Ведут подкаст опытные офицеры в запасе и их друзья.  В программе: — "Основная часть": аналитика военных действий и повседневной жизни армии России. Выражение личного мнения о происходящем вокруг и внутри армий мира.  — "РККА": Реформа Компактно-Карманной Армии - наблюдения за ходом военной реформы. — "миК-граунд": реальные мини рассказы из армейской жизни с юмором, сарказмом и всерьёз. А также байки от друзей. — "Советы мамам": советы мамам от бывалых офицеров, сержантов, солдат. — "Армейская курилка": ликбез от опытных военных для всех, не взирая военный Вы или нет. — "Железяка": все о вооружении и военной технике устами  офицеров. — "Розовая Железяка": как видит и воспринимает вооружение и военную технику женщина. — "Про-армейские новости": обсуждение самых свежих новостей об армии России и мира. — "Армейское перо": литературные и документальные произведения об армии в виде аудио-рассказов. — "Чтобы помнили": коротко о героях, знаменательных датах в истории ВС, орденах, медалях, командирах и просто о солдатах.  Темы программы, как и выпуски — не регулярны. В одном выпуске затрагиваются не все сразу темы.  P.S. У России два союзника — Армия и Флот!	http://file2.podfm.ru/5/52/523/5237/images/lent_5144_big_76.jpg
415	http://artificialcontinuum.jellycast.com/podcast/feed/2	The Artificial Continuum Podcast	artificialcontinuum	Guide To All Things Nerdy	https://artificialcontinuum.jellycast.com/files/Artificial%20Continuum%20sm.jpg
456	http://awesomepedia.org/podcast/rss.php	Hallå Där!	AWESOMEPEDIA.ORG	Hallå Där är en podcast som balanserar på den tunna tråden mellan ironi och hets mot folkgrupp.	http://awesomepedia.org/podcast/images/itunes_image.png
916	http://cityofnorthport.granicus.com/VPodcast.php?view_id=4	North Port, FL: North Port Presents: The View From Here Video Podcast	North Port, FL		http://admin-101.granicus.com/Content/Northport/North_Port_Video_Podcasting.jpg
416	http://art.podfm.ru/rss/rss.xml	Признаки Времени	PodFM.ru	"Признаки Времени" — авторская программа Севы Гаккеля об искусстве и творчестве. Гости программы — музыканты, актеры, художники, режиссеры — все те состоявшиеся творческие личности, которым есть что рассказать слушателям. Ведущий - Сева Гаккель. Звукорежиссер - Анатолий Стрельцов.	http://file2.podfm.ru/10/100/1008/10082/images/lent_11307_big_31.jpg
417	http://arloasutter.hipcast.com/rss/rivercitycommunitychurch.xml	River City Community Church	Daniel Hill	a multi-ethnic community of faith in Chicago	https://arloasutter.hipcast.com/albumart/1001_itunes_1603135208.jpg
418	http://artist.denovation.co.jp/dap.xml	Deno Podcasts	Denovation	Denovation もしくは アーティストに関連する 映像、音楽などを Podcastsを通じて公開します。	http://ark.denovation.co.jp/imgs/img-podcast.jpg
419	http://artificialeyes.tv/ae_indigo_podcast.xml	artificialeyes.tv Loopcast	artificialeyes.tv		http://artificialeyes.tv/images/ae_eye_300.png
420	http://api.sr.se/api/rss/pod/4016	Kaliber	Sveriges Radio	P1:s program för grävande journalistik. Vi granskar missförhållanden och samhällsfenomen.\r\nAnsvarig utgivare: Hanna Toll	https://static-cdn.sr.se/images/1316/3e0432ad-da11-4209-8244-5872343122a6.jpg?preset=api-itunes-presentation-image
421	http://arttrap.com/podcasts/HGBSF/feeds/HitchhikersGuidetoBritishSci-Fi-MP3.xml	Hitchhiker's Guide to British Sci-Fi (MP3)	Louis Trapani	From the creators of Doctor Who: Podshock, a podcast covering all of British science fiction including but not limited to Doctor Who, Blake's 7, Torchwood, Sarah Jane Adventures, UFO, Thunderbirds, Space: 1999, War of the Worlds, The Tripods, The Hitchhiker's Guide to the Galaxy, and more. Hosted by Louis Trapani and friends. (MP3 version). A production of Art Trap Productions. See other podcasts at arttrap.com.	http://arttrap.com/podcasts/HGBSF/images/HGBSF2_1400.jpg
422	http://arttrap.com/podcasts/HGBSF/feeds/HitchhikersGuidetoBritishSci-Fi.xml	Hitchhiker's Guide to British Sci-Fi	Louis Trapani	From the creators of Doctor Who: Podshock, a podcast covering all of British science fiction including but not limited to Doctor Who, Blake's 7, Torchwood, Sarah Jane Adventures, UFO, Thunderbirds, Space: 1999, War of the Worlds, The Tripods, The Hitchhiker's Guide to the Galaxy, and more. Hosted by Louis Trapani and friends. A production of Art Trap Productions. See other podcasts at arttrap.com.	http://arttrap.com/podcasts/HGBSF/images/HGBSF2_1400.jpg
423	http://arvid9.hipcast.com/rss/braincast.xml	Braincast - auf der Frequenz zwischen Geist und Gehirn	Arvid Leyh	Braincast beschäftigt sich mit den Funktionsweisen, Möglichkeiten und Folgen des Gehirns. Jeder Ausgabe dreht sich um ein spezielles Thema, kommt inklusive der woechentlichen News und ist mundgerecht verpackt.	https://arvid9.hipcast.com/albumart/1001_itunes_1602965740.jpg
424	http://as-isnt.com/podcast/feed.xml	As-Isn't Co. Podcast	As-Isn't Co.	AS-ISN'T, WITH NO FAULTS.	http://as-isnt.com/podcast/images/itunes_image.jpg
425	http://ash.nowsprouting.com/covenantcommunitychurch5/podcast.php?pageID=5	Covenant Community Church, Hudsonville, MI	Steve Bristol	The weekly message podcast of Covenant Community Church in Hudsonville, MI	http://mediastorage.cloversites.com/covenantcommunitychurch5/podcast_thumbnails/podcast_5_1358177276.jpg
426	http://ash.nowsprouting.com/anthologychurchofstudiocity/podcast.php?pageid=21	Anthology Church Video Podcast	Anthology Church of Studio City	Messages from the pastors of Anthology Church of Studio City. At Anthology our mission is to be a community uniting our stories together with God's Story to see a greater work in our city. If you'd like more information on us go to our website or contact us at info@anthologychurch.com	http://mediastorage.cloversites.com/anthologychurchofstudiocity/podcast_thumbnails/podcast_21_54cbfdd1cf98c.jpg
427	http://asfradio3.seesaa.net/index20.rdf	A'sf -Pod- Radio	thin-p	My Favorites with Music / Japanese Podcasting by thin-p (Tsuyoshi Adachi) since 2005好きな事を、好きな音楽と共に、世界中のみんなとシェアして、世界中のいろんな人たちとつながっていけたら、なんてなことを思ってやってます。よ。	https://asfradio3.up.seesaa.net/image/podcast_artwork.jpg
148	http://airinterviews.jamanetwork.libsynpro.com/rss	Author in the Room™ Interviews	JAMA Network	In partnership with the Institute for Healthcare Improvement, this program is designed to bring clinical evidence into practice by connecting practitioners to authors of JAMA articles.	http://static.libsyn.com/p/assets/a/7/5/3/a753f698b4a16d9c/authorinroom_podcast-1400px.png
428	http://asiasociety.org/podcasts/anotherpakistan.xml	Another Pakistan	Asia Society	Recorded in Karachi and Lahore in the summer of 2011, Another Pakistan offers a unique view of a complicated country. Host Christopher Lydon interviews singers, story-tellers and artists to paint a picture rarely seen in mainstream media.	http://www.asiasociety.org/podcasts/another_pakistan_logo_500.jpg
429	http://asiasociety.org/files/ChinaGreen/videocasts/chinagreenVideocast.xml	CHINA GREEN Videocast	CHINA GREEN	All About China and Its Environmental Significance, to Asia and to the world.	http://www.asiasociety.org/files/ChinaGreen/videocasts/chinagreenLogo_iTunes.jpg
430	http://asianparadise.sblo.jp/index20.rdf	アジアンパラダイスPodcast	アジアンパラダイス	「アジアンパラダイス」が提供する、アジアのスターや監督などのインタビュー、記者会見ほかの音声コンテンツです。★リンクは有り難いのですが、音声や写真、記事の転載は固くお断りします。	\N
431	http://api.sr.se/api/rss/pod/11327	OBS	Sveriges Radio	Ett forum för den talade kulturessän där samtidens och historiens idéer prövas och möts.\r\nAnsvarig utgivare: Anna Benker	https://static-cdn.sr.se/images/503/3631103_1400_1400.jpg?preset=api-itunes-presentation-image
432	http://assets.sbnation.com/assets/576486/camdencast.xml	Camdencast	Camden Chat	Camden Chat is a blog where fans of the Baltimore Orioles gather to talk about the team or anything else. On the podcast, Mark and Stacey (and occasionally others) discuss the team, Major League Baseball in general, and whatever esoteric interest the conversation stumbles across.	http://cdn3.sbnation.com/community_logos/21584/camden8d-adj.jpg
433	http://assets.winespectator.com/wso/Video/podcast.xml	Wine Spectator Video	WineSpectator.com	Wine Spectator Video	http://www.winespectator.com/contentimage/wso/Video/ws_pod.jpg
917	http://cityofnorthport.granicus.com/VPodcast.php?view_id=5	North Port, FL: Special Programming Video Podcast	North Port, FL		http://admin-101.granicus.com/Content/Northport/North_Port_Video_Podcasting.jpg
434	http://asylum.libsyn.org/rss	JBoss Community Asylum	Max R. Andersen, Emmanuel Bernard and Michael Neale	Podcast for, by and about the JBoss Community. You will hear the latest news as well as in depth discussions about JBoss Community projects.	http://static.libsyn.com/p/assets/a/0/1/1/a0114a347ac14bf1/asylum_ituneslogowhite.jpg
435	http://atgc.atguitarcenter.libsynpro.com/rss	At Guitar Center with Nic Harcourt	Guitar Center	At: Guitar Center with Nic Harcourt is a podcast series featuring intimate performances and insightful interviews with today's most compelling artists. With host Nic Harcourt.	http://static.libsyn.com/p/assets/9/a/a/6/9aa6d276aa1f9729/ATGCNH.jpg
436	http://atomomedia.com/podcast/atomico.xml	El podcast de Don Limon (Cuarta Temporada)	Juan Pablo Torres Limo	Atomico.FM presenta la tercera temporada del podcast de Don Limon.\n	http://atomico.fm/podcast/images/lemon2.jpg
457	http://awsmovie.cafe24.com/venture_s/venture_story.xml	벤처야설 시즌2 - 솔직담백 벤처방송	벤처야설팀	벤처야설 시즌2는 김현진,박영욱,이정우, 각각 벤처 3인방과 함께 하는 벤처 전문 팟캐스트 입니다! 벤처에 대한 솔직 담백한 이야기들을 재미와 감동으로 풀어드리도록 하겠습니다!	http://ppk314.blogcocktail.com/venture_story.png
117	http://abcwiddamob.contentfilm.libsynpro.com/rss	ABC Wid Da Mob	Contentfilm	Spoofing early learning programming, themes such as co-operation, compassion, feeling sad and sharing are taught by a host of misplaced Mafiosi types with unusual ways of demonstrating these valuable life lessons. Just a few of the many important things you will learn are – why The Little Mermaid sleeps with the fishes and how Hansel and Gretel disposed of the witch’s body.	http://static.libsyn.com/p/assets/0/d/b/9/0db9afe54c59730c/raw.jpg
118	http://acidpanda.sakura.ne.jp/podcasting/podcast.xml	ACID PANDA CAFE PODCASTING	ACID PANDA CAFE	1\n	http://acidpanda.sakura.ne.jp/podcasting/APBC.jpg\n
119	http://ablaze.org.au/production/word.xml	Ablaze Weekly Preaching	Ablaze Ministries International	Ablaze Weekly Preaching	\N
120	http://accordionnoir.org/drupal/rss.xml	Accordion Noir Radio - Ruthlessly pursuing the belief that the accordion is just another instrument.	\N	\r\n\r\n\r\n\r\n\r\nAccordion Noir plays punk-rock classical-folk music from around the world, with jazz and an occasional token polka. Broadcast live on CFRO Co-Op Radio from the heart of the Downtown Eastside in Vancouver, British Columbia, Canada, Earth. \r\n\r\n\r\n\r\n\r\n \r\n\r\nPlease \r\nDonate to Co-op Radio. Mention Accordion Noir so they know which show you love.\r\n\r\nYou can find an alternate download site for current shows at \r\nVancouver Co-op Radio's Accordion Noir page\r\n\r\nFor more about Bruce's Accordion History Book Project and various amusements, look at:  www.AccordionUprising.org\r\n\r\n\r\nFor more on Vancouver's accordion scene, go to \r\nThe Vancouver Squeezebox Circle site or join the Circle, spectators welcome (don't feel pressure to play), every first Thursday of the month at Spartacus Books, 684 E. Hastings, Vancouver.\r\n\r\n\r\nWelcome to Accordion Noir; enjoy the squeezings!\r\n	\N
121	http://act.jinbo.net/podcast/jinbonet.xml	진보네트워크센터	진보네트워크센터	진보네트워크센터에서 제공하는 정보인권 관련 미디어입니다.	http://act.jinbo.net/drupal/themes/bone2010/logo.png
125	http://adcorp.co.uk/adpodcast.rss	AD Podcast	\N	March AD Podcast	\N
458	http://b-ring.seesaa.net/index20.rdf	BRING 「B-ring!!」	BRING	J-POProckバンド「BRING」の情報発信番組「B-ring」BRINGがゲストを迎えながら楽しくおしゃべりしちゃいます！！毎月のLIVEでBRINGが皆様に質問をご用意させていただいております。いただいたお返事をVo,Gの高橋雅弘と毎回のゲストでわいわいトークを繰り広げます。	\N
459	http://b2bnewsletter.universal-music.de/podcasts/maxherre/maxherre.xml	Max Herre	Max Herre	Dieser Podcast stellt die iTunes LP von Max Herres Album "Hallo Welt!" vor.	http://b2bnewsletter.universal-music.de/podcasts/maxherre/artwork.jpg
460	http://b180.gniazdoswiatow.net/feed/	B180 – Podcast o Batmanie	B180 - Podcast o Batmanie	Just another WordPress weblog	http://godai.nazwa.pl/b180/wp-content/plugins/podpress/images/powered_by_podpress_large.jpg
461	http://auto.sina.com.cn/xml/planb_rss.xml	汽车测试B计划	新浪汽车	《汽车测试B计划》 新浪汽车旗下高端视频测试栏目	http://i1.sinaimg.cn/qc/2013/0205/U4098P33DT20130205165217.jpg
462	http://baddice.co.uk/?feed=podcast	The Bad Dice Podcast - A Warhammer Age of Sigmar Podcast	Ben Curry	The Age of Sigmar Podcast | All About Warhammer	http://baddice.co.uk/wp-content/uploads/powerpress/baddicefeed1400x1400-441.jpg
463	http://baddog.byoaudio.com/rss/nyjetstherapystarringbaddogandbadpup.xml	NY JETS FAN THERAPY-Post and Pre Game Commentarty	Bad Dog and Bad Pup	NY JETS THERAPY- hosted by Bad Dog and Bad Pup --HUGE JETS FANS for years offer cathartic commentary on the NY JETS through out the season. Each week someone will be in the dog pound whether its a reporter or the clock manager, you will be sure to find cathartic relief with these two.	https://baddog.byoaudio.com/albumart/1000_itunes.1603343677.jpg
464	http://badticeepslyon.free.fr/Badminton_EPS_Lyon/Videos_Niv2/rss.xml	Badminton et EPS - Niveau 2 en collège	Philippe Bouzonnet	Les compétences attendues du niveau 2 sont présentées dans cette partie, en respectant la même organisation et les mêmes indicateurs. Les vidéos viennent illustrer concrètement les définitions des différents comportements caractéristiques des compétences attendues du niveau 2 collège.<br/>Cependant, les vidéos retenues, peuvent à tout moment être remplacées par des vidéos de meilleure qualité ou plus pertinentes.	http://badticeepslyon.free.fr/Badminton_EPS_Lyon/Videos_Niv2/Videos_Niv2_files/Capture%20decran%202011-01-05%20a%2014.42.10.jpg
918	http://cityofnorthport.granicus.com/VPodcast.php?view_id=6	North Port, FL: Governing Bodies Video Podcast	North Port, FL		http://admin-101.granicus.com/Content/Northport/North_Port_Video_Podcasting.jpg
919	http://cityofpalmdesert.granicus.com/Podcast.php?view_id=2	City of Palm Desert, CA: Default View Audio Podcast	City of Palm Desert, CA		http://admin-101.granicus.com/content/cityofpalmdesert/images/podcastImage/cityofpalmedesert.jpg
465	http://badticeepslyon.free.fr/Badminton_EPS_Lyon/Videos_Niv1/rss.xml	Badminton et EPS - Niveau 1 en collège	Philippe Bouzonnet	Les compétences attendues du niveau 1 sont présentées dans cette partie, en respectant la même organisation et les mêmes indicateurs. Les vidéos viennent illustrer concrètement les définitions des différents comportements caractéristiques des compétences attendues du niveau 1 collège.<br/>Cependant, les vidéos retenues, peuvent à tout moment être remplacées par des vidéos de meilleure qualité ou plus pertinentes.	http://badticeepslyon.free.fr/Badminton_EPS_Lyon/Videos_Niv1/Videos_Niv1_files/Capture%20decran%202010-12-20%20a%2017.00.53.jpg
466	http://badticeepslyon.free.fr/Badminton_EPS_Lyon/Videos_Niv3/rss.xml	Badminton et EPS - Niveau 3 en lycée	Philippe Bouzonnet	Les compétences attendues du niveau 3 sont présentées dans cette partie, en respectant la même organisation et les mêmes indicateurs. Les vidéos viennent illustrer concrètement les définitions des différents comportements caractéristiques des compétences attendues du niveau 3 lycée.<br/>Cependant, les vidéos retenus, peuvent à tout moment être remplacés par des vidéos de meilleur qualité ou plus pertinentes.	http://badticeepslyon.free.fr/Badminton_EPS_Lyon/Videos_Niv3/Videos_Niv3_files/Capture%20decran%202011-01-05%20a%2014.44.32.jpg
467	http://badticeepslyon.free.fr/Badminton_EPS_Lyon/Videos_Niv4/rss.xml	Badminton et EPS - Niveau 4 en lycée	Philippe Bouzonnet	Les compétences attendues du niveau 4 sont présentées dans cette partie, en respectant la même organisation et les mêmes indicateurs. Les vidéos viennent illustrer concrètement les définitions des différents comportements caractéristiques des compétences attendues du niveau 4 lycée.<br/>Cependant, les vidéos retenues, peuvent à tout moment être remplacées par des vidéos de meilleure qualité ou plus pertinentes.	http://badticeepslyon.free.fr/Badminton_EPS_Lyon/Videos_Niv4/Videos_Niv4_files/Capture%20decran%202011-01-05%20a%2014.46.00.jpg
468	http://badticeepslyon.free.fr/Badminton_EPS_Lyon/Videos_Niv5/rss.xml	Badminton et EPS - Niveau 5 en lycée	Philippe Bouzonnet	Les compétences attendues du niveau 5 sont présentées dans cette partie, en respectant la même organisation et les mêmes indicateurs. Les vidéos viennent illustrer concrètement les définitions des différents comportements caractéristiques des compétences attendues du niveau 5 lycée.<br/>Cependant, les vidéos retenues, peuvent à tout moment être remplacées par des vidéos de meilleure qualité ou plus pertinentes.	http://badticeepslyon.free.fr/Badminton_EPS_Lyon/Videos_Niv5/Videos_Niv5_files/Capture%20decran%202011-01-05%20a%2014.48.21.jpg
469	http://ballpitelevator.com/category/podcast/feed/	The Ball Pit Elevator Podcast	Ball Pit Elevator	The Ball Pit Elevator Podcast: Video Games, Talk, and Whatever Else	http://ballpitelevator.com/media/powerpress/BPE1400x1400.jpg
470	http://barkradio.com/feed/podcast/	Bark Radio	Bark Radio	We're not done until every dog has a home.	http://barkradio.com/wp-content/plugins/powerpress/itunes_default.jpg
471	http://balticonpodcast.org/wordpress/?feed=podcast	Balticon Podcast » Podcast Feed	podcast@balticonpodcast.org	The Balticon Podcast brings you interviews with the people who make Science Fiction happen.	http://www.balticonpodcast.org/images/bcpc-logo-FPM2-144x144.jpg
472	http://baseballhistorian.rnn.beta.libsynpro.com/rss	Baseball Historian Podcast	Dennis Humphrey	The Baseball Historian hosted by Dennis Humphrey were the past comes alive through podcasting baseballs greatest moments.	http://static.libsyn.com/p/assets/2/8/6/4/28643657da0c39a4/BaseballHistorian.jpg
473	http://basil.is.konan-u.ac.jp/tutor/bunko/gongitsune/gongitsune1.rss	日本語上級者のための日本文学珠玉の小品集	tutor.bunko	\N	http://basil.is.konan-u.ac.jp/tutor/bunko/img/gongitsune_icon.jpg
474	http://bayleysbanter.com/feed/	Bayley's Banter!	Lloyd Bayley	Lloyd Bayley hosts his own podcast from Australia. It is comedy-based and a fun outlet for his unpursued talents.	http://bayleysbanter.com/wp-content/uploads/powerpress/bb-itunes-image.jpg
475	http://bbliveshow.com/feed.xml	BBLiveShow	Adequate.com	Episodes and clips from the live stream of Brian Brushwood and friends, BBLiveShow.	https://bbliveshow.com/episodes/media/BBLiveShow300x300.jpg
476	http://bc.jellycast.com/podcast/feed/2	Famous Blue Raincoat Podcast	Famous Blue Raincoat	Music from artists who perform at The Famous Blue Raincoat.	https://bc.jellycast.com/files/logo%20for%20podcast.png
485	http://feeds.feedburner.com/BossBarrelRadio	Boss Barrel Radio	Boss Barrel	Listen in every week to the Boss Barrel people talk about the video games we are playing, news in the video game industry, and all the off-topic nonsense that slips in.	http://1.bp.blogspot.com/-rLLDKdqhQvU/UgxSVOq-mWI/AAAAAAAAAK0/wKQBjVOMDVw/s250/bossbarrelradio.jpg
536	http://cayenne.libsyn.com/rss	- TEKDIFF (teknikal diffikulties)-	Cayenne Chris Conroy (tekdiff@gmail.com)	Sketch comedy in the vein of The Firesign Theatre, OTR, & Monty Python.  One-man voice team - performing over 400 characters!  No. Not at once, stupid.	https://ssl-static.libsyn.com/p/assets/a/3/6/9/a36925a3cfd08125/Tekdiff_2018_podcast_logo_xmas.png
537	http://cba.fro.at/seriesrss/2102	Kapitalismuskritik (Ex-Vekks)	\N	Diese Sendereihe bietet Inhalte, die man sonst vergeblich sucht:\n1. Auskünfte über die Marktwirtschaft, die nichts mit den besorgten Ratschlägen von Attac oder den Modellen der Nationalökonomie zu tun haben, dafür sehr viel mit dem, was Karl Marx an dieser Ökonomie auszusetzen hatte.\n2. Auskünfte über die Geistes- und Gesellschaftswissenschaften, die sich ihre logischen Fehler und ihre Parteilichkeit für die Macht zum Gegenstand machen.\n3. Auskünfte über den demokratischen Staat, wo darauf verzichtet wird, der Politik die eigenen Ideale nachzutragen und sich dann darüber zu beschweren, daß die schlechte Wirklichkeit hinter ihren guten Möglichkeiten zurückbliebt.\n4. Auskünfte über den Imperialismus und die Konkurrenz der Nationen, die ohne die Beschwörung des Völkerrechts und der Menschenrechte auskommen, und ganz darauf verzichten, die Ereignisse der Welt darauf zu untersuchen, was das denn "für uns" bedeuten könnte.\n\nweitere Infos, zu Veranstaltungen oder Publikationen unter:	https://cba.fro.at/wp-content/uploads/vekks/2102.png
538	http://cba.fro.at/seriesrss/2124	Ellenhang	\N		https://cba.fro.at/wp-content/uploads/series/2124.png
539	http://cbc-md.org/backstageIncludes/BackstageSermons/modules/Podcast/	Calvary Baptist Church Pulpit Sermons	Calvary Baptist Church of Westminster, MD	CBC sermons - expositional preaching from God's Word, the Bible	http://cbc-md.org/site/user/images/cbc_md.jpg
540	http://cbc.podOmatic.com/rss2.xml	Calvary Baptist Church - Grand Rapids, MI	Calvary Baptist Church	Sunday morning sermons from Calvary Baptist in Grand Rapids, MI.	https://assets.podomatic.net/ts/cc/b2/41/cbc/3000x3000_3912122.jpg
562	http://cbspodcast.com/podcast/nocut_issue/nocut_issue.xml	이슈까기	CBS	영화 패러디로 세상을 까다	http://cbspodcast.com/podcast/nocut_issue/issue.jpg
541	http://cbcal.podOmatic.com/rss2.xml	CBCal - Cristãos Brasileiros em Calgary	CBCal - Cristãos Brasileiros em Calgary	Se você não ouviu ou quer ouvir novamente os estudos bíblicos do grupo de Cristãos Brasileiros em Calgary, este é o lugar certo! Mantenha-se atualizado acompanhando e ouvindo as mensagens!	https://assets.podomatic.net/ts/a0/bb/18/cbcal/1400x1400_10885038.gif
542	http://cbcfortworth.org/podcast.php?pageID=22	Calvary Bible Church - Fort Worth, TX	Calvary Bible Church	God-centered, Christ-exalting, expository preaching with a view to helping you worship the Lord with minds engaged and hearts aflame.	https://clovermedia.s3-us-west-2.amazonaws.com/store/c3/c3a498d1-3cfa-437e-b46a-52eba08b3ec0/thumbnails/mobile/447ed1b6-3666-445e-ab59-1d2ec084cf0f.jpg
544	http://cbcpod.libsyn.com/rss	Mannahouse	helpdesk@citybiblechurch.org	Formerly the home of the City Bible Church podcast.\nWe invite you listen to these messages from Mannahouse. We believe they will encourage you, challenge you, and help you learn how to live in this journey. Mannahouse is a multi-campus church in Portland, Oregon. Join us every week at any of our campuses or online at live.mannahouse.church	https://ssl-static.libsyn.com/p/assets/e/0/4/4/e044e2c908fcbce3/MH_Logo_Socials.png
546	http://cbglades.podbean.com/feed/	Church by the Glades	Pastor David Hughes	We’re all about Jesus & His Word. This is the vision of Church by the Glades, led by Pastor David Hughes and based in Coral Springs, FL with multiple locations across South Florida – No Perfect People Allowed.	https://pbcdn1.podbean.com/imglogo/image-logo/443359/PD-Podcast-v2.jpg
547	http://cbhstaylor.podbean.com/feed/	Year 7 Geography at Canterbury Boys		Podcasting in Geography	https://pbcdn1.podbean.com/imglogo/image-logo/16014/CBHScrestforpodbean.jpg
549	http://cblyondancerock.podOmatic.com/rss2.xml	Fixing this, just wait a little longer!!!	CB Lyon	Dance Rock Radio is a blend of rock and dance music, usually both at the same time. CB Lyon is a world class DJ with destinations such as Ibiza, Tokyo, Paris, London, and travels mostly between New York City and Los Angeles. If you are into groups like Coldplay, The Killers, Hellogoodbye, Fiest, Young Love, The Klaxons, Panic! At the Disco, The Bravery, The Smashing Pumpkins, Red Hot Chili Peppers, Fall Out Boy but also enjoying going out and dancing with your friends then DANCE ROCK RADIO is perfect for you.  \nUse to pre game on the weekend, enjoy it when you're stuck in traffic, listen to it in the gym, it's perfect for anytime, all the time.  For more about us check out DanceRock.com.	https://cblyondancerock.podomatic.com/images/default/podcast-3-1400.png
551	http://cbpodcast.podbean.com/feed/	CB Podcast	CB Podcast	Un podcast para los participantes del Concurso Bíblico.	https://pbcdn1.podbean.com/imglogo/image-logo/485552/CB-Logo-2.jpg
554	http://cbspodcast.com/podcast/fifteen_minutes/fifteen_minutes.xml	세바시	CBS	CBS TV 세상을 바꾸는 시간, 15분	http://cbspodcast.com/podcast/fifteen_minutes/new_fifteen_minutes.jpg
556	http://cbspodcast.com/podcast/happynara/happynara.xml	CBS 손숙,한대수의 행복의 나라로	CBS	CBS Radio 표준FM 98.1MHz  월~토 09:05 ~ 11:00	http://cbspodcast.com/podcast/happynara/happynara.jpg
557	http://cbspodcast.com/podcast/jejucbs/church/church.xml	김PD와 함께가는 교회올레	JEJUCBS	JEJUCBS Radio 제주FM 93.3MHz 서귀포FM 90.9MHz 일요일 17:20~17:58/ \n하나님의 사역을 아름답게 감당하는 교회를 찾아가는 길, 그 길은 늘 행복합니다	http://cbspodcast.com/podcast/jejucbs/church/church.jpg
558	http://cbspodcast.com/podcast/kgh_radio/kgh_radio.xml	김광한의 라디오스타	CBS	CBS Radio 표준FM 98.1MHz	http://cbspodcast.com/podcast/kgh_radio/kgh_radio.jpg
559	http://cbspodcast.com/podcast/newshow/newshow.xml	CBS 김현정의 뉴스쇼	CBS	<p>CBS Radio 표준FM 98.1MHz 월~금 07:20~09:00</p>	https://content.production.cdn.art19.com/images/8b/80/3f/8a/8b803f8a-9188-4431-afe5-37437b3d8414/ef736b6917aba7431692873b91ac4c5081af42ebd5efbcce5132f02819a62ddcc05eb3dc54c28b2ea216b0f5e72670c98d7080ec9714f20fe50cfe7dd5ff84f8.jpeg
560	http://cbspodcast.com/podcast/newsshow_journal/newsshow_journal.xml	변상욱 기자수첩[김현정의 뉴스쇼 2부]	CBS	CBS Radio 표준 FM 98.1MHz	http://file.cbs.co.kr/201810/20181001135543.jpg
561	http://cbspodcast.com/podcast/newsshow_topic_interview/newsshow_topic_interview.xml	김현정의 화제의 인터뷰	CBS	CBS Radio 표준 FM 98.1MHz	http://cbspodcast.com/podcast/newsshow_topic_interview/topic.jpg
563	http://cbspodcast.com/podcast/nocutv/en/en.xml	EN	CBS	이것이 진정한 고급, 고화질 엔터테인먼트다! 노컷V EN! 따끈따끈한 방송, 연예, 영화, 뮤지컬, 연극, 공연, 음반, 문화가 소식을 스마트한 동영상으로 손바닥 안에서 즐기세요^^ 한류 스타의 동정이나 뮤직비디오, 영화 예고편 등은 영어 자막으로도 제공됩니다.	http://cbspodcast.com/podcast/nocutv/en/en.jpg
564	http://cbspodcast.com/podcast/nocutv/garasade/garasade.xml	가라사대	CBS	우리는 당신이 그때 한 말을 기억하고 있다! 권력자나 유명인의 언사(言辭)를 통해 보는 말의 역사(言史). 그 궤적을 되짚어 공약(空約)과 허언(虛言), 궤변(詭辯)을 파헤칩니다. 가라의 시대, 이제 그만 가라는 가라^^. CBS가 만드는 스마트미디어 nocutV의 '가라사대' 팟캐스트입니다.	http://cbspodcast.com/podcast/nocutv/garasade/garasade.jpg
565	http://cbspodcast.com/podcast/nocutv/nocutv.xml	nocutV	CBS	새로운 시각으로 세상을 담다! CBS가 만드는 스마트미디어 '노컷V' 팟캐스트입니다.	http://cbspodcast.com/podcast/nocutv/nocutv-1.jpg
566	http://cbspodcast.com/podcast/nocutv/realcar/realcar.xml	레알시승기	CBS	이것이 진정한 시승기다~ 자동차 전문, CBS 김대훈 기자와 정승권 PD가 만드는 노컷V의 요절복통 시승기! 쉽고 재미있고 알차게, 일반 사용자의 눈높이로 거침없이 해부합니다.	http://cbspodcast.com/podcast/nocutv/realcar/realcar.jpg
567	http://cbspodcast.com/podcast/nocutv/soota/soota.xml	수타만평	CBS	요지경 세상, 만화로 뽑아보는 재미가 있다! 날카로운 풍자로 유명한 CBS 권범철 화백의 명품 만평을 애니메이션 동영상에 담아 노컷V에서 선보입니다. 매주 2회 업데이트됩니다~	http://cbspodcast.com/podcast/nocutv/soota/soota.jpg
568	http://cbspodcast.com/podcast/sisa/sisa.xml	시사자키 정관용입니다	CBS	CBS Radio 표준FM 98.1MHz  월~금 18:00~20:00	http://cbspodcast.com/podcast/sisa/j_si.jpg
569	http://cbspodcast.com/podcast/tobe_new/tobe_new.xml	새롭게 하소서	CBS	CBS Radio 새롭게 하소서	http://cbspodcast.com/podcast/tobe_new/new_tobe4.jpg
570	http://cbspodcast.com/podcast/with_you/with_you.xml	송재호 장로의 QT 동행	CBS	CBS TV 송재호 장로의 QT 동행	http://cbspodcast.com/podcast/with_you/with_you.jpg
572	http://cc.catholic.or.kr/podcast/?code=1	생명의 말씀	천주교 서울대교구 홍보위원회	한 주간의 복음과 강론을 들려드립니다. 주일 복음 말씀은 서울대교구 신부님께서 직접 녹음하셨습니다. 생명을 주는 복음 말씀과 강론을 놓치지 마세요!	http://cc.catholic.or.kr/popcast/img/saengmyeong.jpg
573	http://cc.catholic.or.kr/podcast/?code=2	지영&지영 교리쇼	천주교 서울대교구 홍보위원회	재미있는 신개념 교리시간! 독산1동 성당 김지영 신부님과 팟캐스트 진행자 김지영 도미니카 씨가 평소에 궁금했던 가톨릭 교리상식을 쉽고 재미있게 알려드립니다.	http://cc.catholic.or.kr/popcast/img/jiyoungshow.jpg
574	http://cc.catholic.or.kr/podcast/?code=3	말씀의 이삭	천주교 서울대교구 홍보위원회	서울주보 ‘말씀의 이삭’란에 기고했던 가톨릭 문화예술인을 만나봅니다. 팟캐스트 진행자 안선영 카타리나 씨가 이들을 직접 찾아가 근황을 듣고 생활 속에서 체험한 신앙 이야기를 함께 나눕니다.	http://cc.catholic.or.kr/popcast/img/malssuemisac.jpg
575	http://cc.catholic.or.kr/podcast/?code=4	명동살롱	천주교 서울대교구 홍보위원회	가톨릭 뉴스와 함께하는 티타임. 교회의 중요한 현안부터 소소한 이야기까지, 교구 소식을 허영엽 신부님과 안선영 카타리나, 김지영 도미니카 씨가 유쾌하게 전달해 드립니다.	http://cc.catholic.or.kr/popcast/img/myeongdongsalon.jpg
576	http://cc.libsyn.com/rss	C.C. Chapman		Video, Audio, Music & Whatever Else!	https://ssl-static.libsyn.com/p/assets/c/e/c/7/cec74f5a804d1212/soapy.png
578	http://cc.readytalk.com/f/s1opufh/rec.xml	CSU - Observations From the Stands	Kevin Barnes and Josh White	Our podcast is for those interested in Rams Football! Comments always welcome at ramfan -- (@) -- teampodcast.com	\N
580	http://ccbcmedia.org/podcasts/rss3.xml	Capitol City Sermons Podcast	Capitol City Baptist Church	The weekly sermons from the pulpit of Capitol City Baptist Church in Austin, Texas.	http://ccbcmedia.org/podcasts/logo1.png
583	http://cccc.podOmatic.com/rss2.xml	C4: A Christian Companion's Combative Creed	Crash, ZJ, and Kaine!	Listen to 3 army wives, go through the Christian life.	https://cccc.podomatic.com/images/default/podcast-3-1400.png
587	http://cccraleigh.org/feeds/sermons	Christ Covenant Church	Nik Lingle	Sermons	https://www.csmedia1.com/cccraleigh.org/christ-covenant-squarepod.jpg
588	http://ccecyouth.podomatic.com/rss2.xml	on the poddy	onthepoddy.com	"On the Poddy with Dave & Dan" was a legendary podcast from CCECYOUTH that ran for two glorious years.\n\nWe had a killer time chatting about Jesus, youth group and life.\n\nListen to our 85 episodes. If you want to leave any comments, leave them in the most recent post.\n\nPeaceout.	https://assets.podomatic.net/ts/58/d0/0f/ccecyouth/1400x1400_1379721.gif
589	http://cchc.podomatic.com/rss2.xml	Uncle B's Podcast	Billy Yip	情與緣：聊談友情高境界．希望之來源．	https://assets.podomatic.net/ts/b9/e0/5c/cchc/1400x1400_607011.jpg
590	http://cci.libsyn.com/rss	c3i's Podcast	c3i	We at Cornerstone Christian Church International would like to welcome you to come and worship with us on the internet.\n\nWe believe you will receive a blessing from listening to our worship service and we'll certainly count it a blessing to have you with us when you visit Miami Florida. \n\nIt is our greatest desire that the word of God would be preached truthfully, completely, and passionately, so that all may know of God's great love and His eternal plan for us. \n\nMay the Lord continue to richly bless you with all the spiritual blessings which are in Christ Jesus!\n\nFind us on the web at http://www.cornerstoneinternational.net	http://static.libsyn.com/p/assets/7/d/d/6/7dd62eb77a7e57f2/gpn.jpg
591	http://ccia.libsyn.com/rss	Crash Course In Awesome	Bryan Murdoch and Ricky Silva	Ricky and Bryan pick an Awesome topic and give you a quick Crash Course in it.  From The Unexplained to Movies to Childhood Nostalgia the guys bring you the information you want to know as well as (oh jeez we hope) lots of laughs!  \nAnd it's Awesome.	https://ssl-static.libsyn.com/p/assets/8/4/5/8/845885fe4bb9e6b9/CCIA_Thumbnail.png
592	http://ccicnvraize.wordpress.com/feed/	Welcome to CCIC NV (P)raiZe Podcasts!	\N	The archives for CCIC North Valley's Sunday and Friday messages or activities	https://s0.wp.com/i/buttonw-com.png
660	http://cfbcoldpaths.podomatic.com/rss2.xml	Central Fellowship Baptist Church 2011 Old Paths Conference	Central Fellowship Baptist Church - 2011 Old Paths Conference		https://cfbcoldpaths.podomatic.com/images/default/podcast-4-3000.png
1040	http://colinturnbull.podOmatic.com/rss2.xml	colin turnbull   ...:::music:::..	colin turnbull	TECH HOUSE!! TECH BREAKS !!  TECH FUNK!!!   ELECTRO!!! PROGRESSIVE!!\n\nor.....IS IT JUST ELECTRONIC MUSIC???\n\n..... To dance to!!!\n\nWith influences from artists like The Chemical Brothers, The Crystal Method, Orbital, Rabbit in The Moon, Moby, Meat Katie, Dylan Rhymes, BT, NIN, TOOL, Soundgarden, Lee Coombs, Sasha, John Digweed, Taylor, Dj Dan, Jim Hopkins, The Electroliners, Scott Henry, Friction and Spice, Hyper, Hybrid, Miles Dyson, Donald Glaude, and many others!  \n\nExpect some great new mixes filled with drops, cuts, spins, and scratches to appear on the regular!  not to mention a few old school and classic sets and tracks.. to be dropped in between!!  \n\nAlso look out for lots of new releases and remixes.  you can catch preview of these @  http://www.myspace.com/colinturnbull\n\nworking on lots of new stuff!! including a new site.. Tons of new REMIXES and NEW PRODUCTION!\n\nEXPECT some of these to be exclusively DROPPED in Future Podcasts!!!\n\n"I take risks, experiment, and always try new things..... \n.. If I didn't.... I'd be just like every other DJ!\n..Where's the fun in that!"\n\n; )\n\nStay Tuned..    and THANKS FOR SIGNING UP!!!\n(click the subscribe to ITUNES link below)\n\n(((-_-)))\n\n\nFOR BOOKINGS:::: dj.colinturnbull@gmail.com\n\nFOR MAIL LIST:  dj.colinturnbull@hotmail.com\n\nFB.init("f25c33b9586d35134b995d9adea8273c");colin turnbull on Facebook\n\n\n\nnew TWTR.Widget({\n  version: 2,\n  type: 'profile',\n  rpp: 4,\n  interval: 6000,\n  width: 250,\n  height: 300,\n  theme: {\n    shell: {\n      background: '#333333',\n      color: '#ffffff'\n    },\n    tweets: {\n      background: '#000000',\n      color: '#ffffff',\n      links: '#4aed05'\n    }\n  },\n  features: {\n    scrollbar: false,\n    loop: false,\n    live: false,\n    hashtags: true,\n    timestamp: true,\n    avatars: true,\n    behavior: 'all'\n  }\n}).render().setUser('colin_turnbull').start();	https://assets.podomatic.net/ts/42/88/20/colinturnbull/3000x3000_2152262.jpg
595	http://ccohs.libsyn.com/rss	Health and Safety To Go!	Jennifer Miconi-Howse	CCOHS produces monthly podcasts on a wide variety of topics related to workplace health and safety.  Each episode is designed to keep you current with information, tips and insights into the health, safety and well-being of working Canadians. Best of all, they’re FREE! Take a listen to an episode of Health and Safety To Go! You can download the audio segment to your computer or MP3 player and listen to it at your own convenience . . . or on the go!	https://ssl-static.libsyn.com/p/assets/c/8/e/3/c8e38298bbc07227/ccohs_logo.png
596	http://ccragg123.libsyn.com/rss	ChatChat - Claudia Cragg	Claudia Cragg	Feature interviews from journalist and broadcaster, Claudia Cragg	http://static.libsyn.com/p/assets/6/8/a/2/68a2c8bd61af77eb/ClaudiaCragg.jpg
598	http://cctntv.podomatic.com/rss2.xml	CCTN presents: The Sunday Homily	CCTN	This podcast is a community service from The Catholic Community of St. Paul in Leesburg, FL	https://assets.podomatic.net/ts/41/d8/25/cctntv/1400x1400-1197x1197+3+0_6035843.jpg
599	http://ccwpodcast.podomatic.com/rss2.xml	CCW Podcast	CCW Podcast	This is a podcast about legally carrying a concealed weapon (CCW).  Join the show's hosts, husband and wife duo Al and Dagny, as they explore gun ownership and the carry lifestyle.  For current and prospective CCW permit holders alike.  Stay tuned and Semper Portare!	https://assets.podomatic.net/ts/e8/b0/5a/ccwpodcast/3000x3000_8858352.jpg
602	http://cdenney.podOmatic.com/rss2.xml	Ms. Denney's Podcast	cdenney	Students record their original stories.	https://assets.podomatic.net/ts/14/39/53/cdenney/1400x1400_607598.jpg
603	http://cdkillerspodcast1.podomatic.com/rss2.xml	CD Killers' Podcast	CD Killers		https://cdkillerspodcast1.podomatic.com/images/default/podcast-4-1400.png
605	http://cdmixxer.podbean.com/feed/	CD Mixes	Scary Music Collector	A weekly podcast for all SCARY Classical music loverz. different artist too! and the best part is its free sooooooooooooooooooo check it out every week	https://pbcdn1.podbean.com/imglogo/image-logo/43359/fff.jpg
608	http://cdn.celluleute.de/celluleuterss/celluleute.rss	Celluleute Podcast	Celluleute	Altes, neues, trashiges, elegantes aus der Filmwelt.	http://cdn.celluleute.de/celluleuterss/logo1-web.jpg
609	http://cdn.mavenwire.com/videos/mwpodcast/podcast.xml	MW Podcast	MavenWire	MavenWire's Podcast series covering Oracle Transportation Management (OTM) and Global Trade Management (GTM).	http://cdn.mavenwire.com/videos/mwpodcast/MWLogo.jpg
610	http://cdn.osisoft.com/corp/en/media/podcasts/Podcast.xml	OSIsoft PI Geeks Podcast	Glenn and Stuart	An audio show of your questions, answered by OSIsoft insiders. Perfect for listening to anywhere, even in your car or on a plane.	http://cdn.osisoft.com/corp/en/media/podcasts/Stuart_Glenn.png
614	http://cdn.sqexeu.com/files/tombraider/crystalhabit.xml	The Crystal Compass	Crystal Dynamics	The Crystal Compass podcast provides a glimpse inside veteran game studio Crystal Dynamics, best known for its work on the Gex, Legacy of Kain, and Tomb Raider franchises. Tune in monthly for exclusive news, insights, and interviews.	http://cdn2.netops.eidosinteractive.com/files/tombraider/crystalcompass,jpg
615	http://cdn.techguide.com.au/podcast/techguide.xml	Tech Guide	Stephen Fenech	Tech Guide editor Stephen Fenech looks at the latest consumer technology news and reviews, talks to industry figures and answers all of your burning technology questions in his weekly podcast. It's the best way to stay updated and educated	http://cdn.techguide.com.au/podcast/tg-pod-cast-large.jpg
616	http://cdn.thesecretcabal.com/scpodcast.xml	The Secret Cabal Gaming Podcast	Jamie Keagy	Five old friends of more than 20 years come together to produce a high quality, bi-weekly podcast about tabletop gaming of all kinds: board games, card games, miniatures, role-playing games and much more. In each episode you can expect board game reviews, gaming industry news and round-table discussions. The Founders, Jamie, Tony, Chris, Steve and Brian, each have varying tastes in gaming to provide a variety of viewpoints. Since 2011, over 100 full length episodes and now more with our new additional show, The Secret Cabal Express, The Secret Cabal has grown to one of the most successful tabletop gaming podcasts in the community. The Founders continue striving to offer irreverent entertainment, thoughtful commentary and enthusiasm about a hobby we love. Topics include discussion of games from publishers such as Asmodee, Cool Mini or Not, Fantasy Fight Games, Wizards of the Coast, Z-Man Games, Days of Wonder, Games Workshop, Plaid Hat Games and more.	http://cdn.thesecretcabal.com/TheSecretCabalGamingPodcast-2020Logo.png
618	http://cdn.wv.gov/otfeed.xml	WV OISC Basics Podcast	WV OISC	The Basics of Cyber Security at the State of WV	http://www.technology.wv.gov/site-images/header_wvot2.jpg
633	http://cdwarf.libsyn.com/rss	SX3	SX3	Chicks talking guns (and the occasional lucky dude). Yes, you read that correctly. Come have a listen while we chat about our adventures in the gun world. Man or woman, no discrimination here!	https://ssl-static.libsyn.com/p/assets/0/5/5/9/055963181dbd5898/SX3_SKULL_RESIZED.jpg
634	http://cea.podbean.com/feed/	The cea's Podcast	cea	New podcast weblog	https://djrpnl90t7dii.cloudfront.net/podbean-logo/podbean_54.jpg
635	http://cedarcreek.podOmatic.com/rss2.xml	Cedar Creek Church's Podcast	cedarcreek	Sunday messages from Cedar Creek Church in Aiken, SC	https://assets.podomatic.net/ts/37/4f/b0/cedarcreek/pro/3000x3000_6244428.jpg
643	http://celebrity-workout.podomatic.com/rss2.xml	Brad Campbell's Celebrity Workout	Brad Campbell	Hi Im Brad! Doctor of Pharmacy, Personal Trainer, Fat Loss Coach, Lean Body Expert,  Accomplished Author, Blogger, Fat-Hater, Wannabe Hip-Hop Artist (or backup dancer) and One Cool Ass Dude (Self-Proclaimed, of course). More at http://www.topfatlosstrainer.com	https://assets.podomatic.net/ts/a9/04/58/celebrityworkout59112/3000x3000_3627191.jpg
645	http://cellarreserve.podomatic.com/rss2.xml	Free Drinks Next Week	Free Drinks Next Week	A show full of conversations that happen when you talk about alcohol.	https://assets.podomatic.net/ts/ca/c5/19/cellarreserve/3000x3000_9663077.jpg
647	http://celticrootscraic.podomatic.com/rss2.xml	Celtic Roots Craic – Irish Podcast	Raymond McCullough: Precious Oil Productions Ltd, Northern	All the craic from the Celtic Roots Radio shows by Raymond McCullough\n\nProduced by Precious Oil Productions Ltd, Northern Ireland, UK	https://assets.podomatic.net/ts/eb/28/20/raymond22666/3000x3000_4862490.jpg
662	http://cfcmain.libsyn.com/rss	Cornerstone Fellowship Church	Cornerstone Fellowship Church	Cornerstone Fellowship Church is a place where you will find people just like you... people who take care of families, go to work or school, have hobbies, and long for their lives to have significance. In a world that has become hurried and isolated, Cornerstone Fellowship Church is a community of people who are focused on building meaningful relationships. We are a rapidly growing, Non-Denominational, Spirit filled church located in beautiful Mathews County, VA.	https://ssl-static.libsyn.com/p/assets/5/4/8/4/54847656a1b12b7c/Cfcpodcast_sunday_morning.jpg
648	http://celticrootsradio.podOmatic.com/rss2.xml	Celtic Roots Radio – Irish music podcast	Raymond McCullough: Precious Oil Productions Ltd	Celtic Roots Radio (celticrootsradio.com)\n\nHere's a taste a' music to whet yer appetite – Celtic, folk, folk/rock, Appalachian, Breton, bluegrass, Scottish, Irish, Cajun, Cape Breton, singer/songwriter –\nif its Celtic, roots or acoustic music you want,\nyou'll find it here (plus a wee drop a' Norn Iron craic!) – on Celtic Roots Radio!\n----------------\n\nProduced by Precious Oil Productions Ltd\nfor Celtic Roots Radio (celticrootsradio.com)\n----------------\n\n\n24/7 INTERNET STATION!!\nWe also have a 24/7 Celtic Roots Radio web station:\nCheck it out NOW!! at: http://celticrootsradio.fastcast4u.com\n----------------\n\nAlso, check out other podcasts from: \n\nRaymond McCullough \n(raymondmccullough.com &  raymondmccullough.podomatic.com), \nGerry McCullough – Irish writer & poet \n(gerrymccullough.com & gerrymccullough.podomatic.com), \nand Precious Oil Productions Ltd (www.preciousoil.com) \n\n- just enter 'raymond mccullough' into an Apple Podcast search!	https://assets.podomatic.net/ts/88/c3/fe/celticrootsradio/pro/3000x3000_1222427.jpg
653	http://centralchristianbc.podomatic.com/rss2.xml	Central Christian Church Battle Creek	Central Christian Church BC	Sermons from Central Christian Church.	https://assets.podomatic.net/ts/c2/58/69/btheninger/3000x3000_7044043.jpg
658	http://ceresastrology.libsyn.com/rss	Hermetic Astrology Podcast	Gary P Caton	One of the top Astrology Podcasts for more than a decade, Hermetic Astrology Podcast features illuminating, inspirational and transformative correspondence between the primal powers of Above & Below...-more at www.DreamAstrologer.com	https://ssl-static.libsyn.com/p/assets/6/f/7/2/6f72185d1eeb51cb/Hermetic.jpg
659	http://cesarporto.podOmatic.com/rss2.xml	CP's Podcast	Cesar Porto		https://cesarporto.podomatic.com/images/default/podcast-1-1400.png
663	http://cffchurch.libsyn.com/rss	CFFC's Podcast	Christian Faith Fellowship Church	Tune in to the weekly services at Christian Faith Fellowship Church, located in Hardyston, NJ. We are a non-denominational church, dedicated to sharing the Good News of the Gospel of Jesus Christ!	https://ssl-static.libsyn.com/p/assets/8/2/1/3/8213e3a887169c00/CMG_Editor_-_June_23_2020_4.jpeg
667	http://cfs.tistory.com/custom/blog/18/187772/skin/images/PHS_Cast_M.xml	박효신의 주맘 캡틴플래닛	Captain Planet	PHS Cast M	http://cfs.tistory.com/custom/blog/18/187772/skin/images/phscast2.png
672	http://cfwindsprints.libsyn.com/rss	Jerry Cahill's CF Wind Sprints	Jerry Cahill	Jerry Cahill used the short video format to educate and inspire people with cystic fibrosis to utilize exercise to improve health.	http://static.libsyn.com/p/assets/c/d/d/5/cdd5e258c6e00579/WindSprintsLogoforLibsyn.jpg
675	http://cgcpueblo.libsyn.com/rss	cgcpueblo podcast	Maceo Montez	see www.cgcpueblo.org	http://static.libsyn.com/p/assets/a/c/8/b/ac8b8c8aa079b942/cgc_logo_new.png
676	http://cgdev.libsyn.com/rss	The CGD Podcast	Center for Global Development	International development experts share their ideas on how wealthy countries can promote prosperity in developing countries.	https://ssl-static.libsyn.com/p/assets/7/8/c/8/78c8a43e72719d92/CGD-logo-1920-RGB-square.png
677	http://cgrocks.libsyn.com/rss	Common Ground Christian Church	Common Ground Christian Church	Missed a Sermon?  Download it Here!	https://ssl-static.libsyn.com/p/assets/5/d/f/b/5dfb7182214ec04b/CGLogo17c.jpg
678	http://cgtruth.org/podcasts/podcast01/podcast01.xml	Pastor Joe Sugrue - Grace and Truth Podcast	Pastor Joe Sugrue	Grace and Truth Ministries is non-denominational, and Pastor Joseph P. Sugrue is dedicated to teaching the Word of God from the original languages.	http://www.cgtruth.org/podcasts/podcast01/podcast01.jpg
682	http://chaatmasala.podomatic.com/rss2.xml	Chaat Masala	Chaat Masala	Bollywood news, views and movie reviews - tadka laga ke! Catch our bollywood know-it-alls, Basanti and Paro bringing you the best of B'wood every week!\n\nJoin our facebook page - https://www.facebook.com/pages/Chaat-Masala\n \nand on \n\nTwitter! - http://twitter.com/#!/masala_chaat	https://assets.podomatic.net/ts/60/95/a4/chaatmasalaradio/pro/3000x3000_4372974.jpg
683	http://chadjack.podomatic.com/rss2.xml	DJ Chad Jack Presents "GIGABEATS!"	Chad Jack	NYC DJ/ Producer Chad Jack Presents "Gigabeats" Podcast	https://assets.podomatic.net/ts/fb/7d/2a/chad62861/3000x3000_3616213.jpg
686	http://challengers.libsyn.com/rss	Contest of Challengers	Patrick Brower	From Challengers Comics + Conversation in Chicago, this is Contest of Challengers, a podcast about the business of running a comics shop. From publishers to distributors to the sales floor itself, each episode deals with the issues of the week and how they affect the way Challengers conducts business, and that includes the actual comic book issues themselves. Hosted by Patrick Brower and W. Dal Bush. Thanks for listening. Keep Reading Comics!	https://ssl-static.libsyn.com/p/assets/1/6/f/d/16fd41574413d808/CoC_Libsyn_2020_Red.jpg
687	http://chancedorland.podomatic.com/rss2.xml	Chance and Dan DO KOREA	Chance and Dan DO KOREA	Visit Facebook.com/DoKoreaPodcast for details on the new LIVE variety show at Rocky Mountain Tavern.	https://assets.podomatic.net/ts/a4/82/54/chancedorland/1400x1400_4320124.jpg
688	http://chandra.harvard.edu/resources/podcasts/hd/podcasts.xml	The Beautiful Universe: Chandra in HD	cxcpub@cfa.harvard.edu (Chandra webmaster)	High definition views of Chandra's exciting science	https://chandra.harvard.edu/resources/podcasts/hd/hdimage_300.jpg
689	http://chandra.harvard.edu/resources/podcasts/podcasts.xml	Chandra X-ray Observatory Podcasts: Chandra in SD	cxcpub@cfa.harvard.edu (Chandra webmaster)	NASA's Chandra X-ray Observatory Podcasts :: Recent Discoveries from NASA's Chandra X-ray Observatory in an Audio/Video Format	http://chandra.harvard.edu/resources/podcasts/images/sd_podcast_thm100.jpg
692	http://channel1.podbean.com/feed/	Catwalk Fusion - Fashion Show Music	Sandeep Khurana	Fashion Show Music Catwalk Fusion\nSandeep Khurana, SK Infinity\nVoice Madhu	https://pbcdn1.podbean.com/imglogo/image-logo/128079/catwalk1.jpg
693	http://channel9.msdn.com/Blogs/How-Do-I/feed/mp4	How Do I  (MP4) - Channel 9	Microsoft	These short 10- to 15 minute videos focus on specific tasks and show you how to accomplish them step-by-step using Microsoft products and technologies.	http://files.channel9.msdn.com/thumbnail/6f299760-8b31-4e07-91c9-35d11061a35c.png
694	http://channel9.msdn.com/Blogs/Subscribe/feed/mp4	Subscribe!  (MP4) - Channel 9	Microsoft	Subscribe! is a video blog about Messaging, Middleware, Architecture, and all sort of other interesting topics around building larger and more sophisticated solutions than your average website on Windows Azure and Windows Server. Your host and, mostly, mo	http://files.channel9.msdn.com/thumbnail/140b90d8-2659-474a-bf45-02348db7cd56.png
695	http://channel9.msdn.com/Blogs/Subscribe/feed/mp4high	Subscribe!  (HD) - Channel 9	Microsoft	Subscribe! is a video blog about Messaging, Middleware, Architecture, and all sort of other interesting topics around building larger and more sophisticated solutions than your average website on Windows Azure and Windows Server. Your host and, mostly, mo	http://files.channel9.msdn.com/thumbnail/140b90d8-2659-474a-bf45-02348db7cd56.png
696	http://channel9.msdn.com/Events/Build/2012/RSS/mp4high	Build 2012 Sessions (HD)	\N	Sessions for Build 2012	\N
697	http://channel9.msdn.com/Events/GoingNative/GoingNative-2012/RSS/mp4high	GoingNative 2012 Sessions (HD)	\N	Sessions for GoingNative 2012	\N
698	http://channel9.msdn.com/Events/Lang-NEXT/Lang-NEXT-2012/RSS/mp4high	Lang.NEXT 2012 Sessions (HD)	\N	Sessions for Lang.NEXT 2012	\N
699	http://channel9.msdn.com/Events/Patterns-Practices-Symposium-Online/Patterns-Practices-Symposium-Online-2012/RSS/mp4high	Patterns & Practices Symposium Online 2012 Sessions (HD)	\N	Sessions for Patterns & Practices Symposium Online 2012	\N
700	http://channel9.msdn.com/Series/Build-your-first-Windows-Store-app/feed/mp4high	Build your first Windows Store app (HD) - Channel 9	Microsoft	This multi-part video series walks developers through building their first Windows Store app, based on the step-by-step tutorials at dev.windows.com. 1. JavaScript tutorial2. VB/C# tutorial	http://files.channel9.msdn.com/thumbnail/11ebcfba-dd87-4553-a7b0-0d0e59eb843e.png
716	http://channel9.msdn.com/shows/SilverlightTV/feed/ipod/	Silverlight TV (MP4) - Channel 9	Microsoft	Go behind the scenes at Microsoft with John Papa and learn what the Silverlight product team is dreaming up next. See exclusive interviews with the Silverlight product team, watch how community leaders are using Silverlight to solve real problems, and keep up with the latest happenings with Silverlight. Catch the inside scoop on Silverlight with Silverlight TV every Thursday at 9am PT! Follow us on Twitter @SilverlightTV where you can send us questions and requests for future shows.	http://files.channel9.msdn.com/itunesimage/c0758e72-6a90-45b7-aebe-292ac09b3072.png
701	http://channel9.msdn.com/Shows/C9-GoingNative/feed/mp4high	C9::GoingNative (HD) - Channel 9	Microsoft	C9::GoingNative is a show dedicated to native development with an emphasis on C&#43;&#43; and C&#43;&#43; developers. Each episode will have a segment including an interview with a native dev in his/her native habitat (office) where we'll talk about what they do and how they use native code and associated toolchains, as well as get their insights and wisdom—geek out. There will be a small news component or segment, but the show will primarily focus on technical tips and conversations with active C/C&#43;&#43; coders, demonstrations of new core language features, libraries, compilers, toolchains, etc. We will bring in guests from around the industry for conversations, tutorials, and demos. As we progress, we will also have segments on other native languages (C, D, Go, etc...). It's all native all the time. You, our viewers, fly first class. We'll deliver what you want to see. That's how it works. Go native! ---&gt; Please follow us at @C9GoingNative on Twitter!	https://f.ch9.ms/thumbnail/1aded85e-91ff-4d46-ad2f-c5a4a4bbc5b8.jpg
702	http://channel9.msdn.com/Shows/Cloud+Cover/feed/mp4high	Microsoft Azure Cloud Cover Show (HD) - Channel 9	Microsoft	Microsoft Azure Cloud Cover is your eye on the Microsoft Cloud. Join Chris Risner and Thiago Almeida as they cover Microsoft Azure, demonstrate features, discuss the latest news &#43; announcements, and share tips and tricks.	https://f.ch9.ms/thumbnail/c63fe544-2385-4869-9b93-83131a771685.png
703	http://channel9.msdn.com/Shows/Defrag-Tools/feed/mp4high	Defrag Tools (HD) - Channel 9	Microsoft	Defrag Tools with Andrew Richards and Chad Beeder	https://f.ch9.ms/thumbnail/66c8d535-6008-49a3-bff1-ac85180f953f.png
704	http://channel9.msdn.com/Shows/Going+Deep/feed/mp4high	Going Deep (HD) - Channel 9	Microsoft	Charles Torre travels around Microsoft to meet the company’s leading Architects and Engineers to discuss the inner workings of our core technologies. Going Deep is primarily concerned with how things work, why they are designed the way they are, and how they will evolve over time. Going Deep also includes lectures by domain experts and conversational pieces amongst computer scientists, architects and engineers (a la E2E).	https://rev9.blob.core.windows.net/thumbnail/0c464bbc-0ef1-4717-a901-5336fc8ff40c.png
705	http://channel9.msdn.com/Shows/HanselminutesOn9/feed/mp4high	Hanselminutes On 9 (HD) - Channel 9	Microsoft	Scott Hanselman works for Microsoft as a Principal Program Manager in Web Platform and Tools, aiming to spread the good word about developing software, very often on the Microsoft stack. Before this he was the Chief Architect at Corillian Corporation, now a part of Checkfree, for 6&#43; years. He was also involved in a few Microsoft Developer things for many years like the MVP and RD programs and will speak about computers (and other passions) whenever someone will listen. He's written a few books, most recently with Bill Evjen and Devin Rader on ASP.NET. He blogs at http://www.hanselman.com, audio podcasts at http://www.hanselminutes.com and http://thisdeveloperslife.com. Sometimes he wanders the halls of Microsoft with a video camera and those videos become…Hanselminutes on 9.	http://files.channel9.msdn.com/thumbnail/67cfd3c5-2f9a-46a9-b6b1-8aba795f65fd.png
706	http://channel9.msdn.com/Shows/Hot-Apps/feed/mp4high	Hot Apps (HD) - Channel 9	Microsoft	Give her 5 minutes, she'll give you 5 Hot Apps! Laura gives you her selections for the weeks hottest apps for Windows Phone 7.	http://files.channel9.msdn.com/thumbnail/44ee39ff-aa21-4f39-980c-3e38e2a698a6.jpg
707	http://channel9.msdn.com/Shows/Inside+Windows+Phone/feed/mp4high	Inside Windows Phone (HD) - Channel 9	Microsoft	Get the insiders’ view into all things Windows Phone. Watch  exclusive interviews with the designers, product managers and developers coding the Windows Phone OS and developer platform	http://files.channel9.msdn.com/thumbnail/ecda5d69-f848-465e-978d-51b7fb1be1a6.png
708	http://channel9.msdn.com/Shows/PingShow/feed/mp4high	Ping! (HD) - Channel 9	Microsoft	Mark DeFalco (@MarkDeFalco) and Rick Claus (@RicksterCDN) dish out cool and interesting news based on what Microsofties are pinging each other about over IM, email, Twitter, and Facebook.	http://files.channel9.msdn.com/thumbnail/0d49ebdf-ffbe-4cf9-80ea-ecddc07bb505.png
709	http://channel9.msdn.com/Shows/SilverlightTV/feed/mp4high	Silverlight TV (HD) - Channel 9	Microsoft	Go behind the scenes at Microsoft with John Papa and learn what the Silverlight product team is dreaming up next. See exclusive interviews with the Silverlight product team, watch how community leaders are using Silverlight to solve real problems, and keep up with the latest happenings with Silverlight. Catch the inside scoop on Silverlight with Silverlight TV every Thursday at 9am PT! Follow us on Twitter @SilverlightTV where you can send us questions and requests for future shows.	http://files.channel9.msdn.com/itunesimage/c0758e72-6a90-45b7-aebe-292ac09b3072.png
710	http://channel9.msdn.com/Shows/TechNet+Radio/feed/mp3	TechNet Radio (Audio) - Channel 9	Microsoft	The podcast for anyone who is passionate about IT. We go deep into the technologies you live with, and the people that build, deploy and manage these. Each week we offer a critical voice, ranging from your IT peers, Microsoft insiders and industry leaders	https://f.ch9.ms/thumbnail/fbf0a3bf-4e7f-41b3-b178-7dff43353f5e.png
711	http://channel9.msdn.com/Shows/TechNet+Radio/feed/mp4	TechNet Radio (MP4) - Channel 9	Microsoft	The podcast for anyone who is passionate about IT. We go deep into the technologies you live with, and the people that build, deploy and manage these. Each week we offer a critical voice, ranging from your IT peers, Microsoft insiders and industry leaders	https://f.ch9.ms/thumbnail/fbf0a3bf-4e7f-41b3-b178-7dff43353f5e.png
712	http://channel9.msdn.com/Shows/TechNet+Radio/feed/mp4high	TechNet Radio (HD) - Channel 9	Microsoft	The podcast for anyone who is passionate about IT. We go deep into the technologies you live with, and the people that build, deploy and manage these. Each week we offer a critical voice, ranging from your IT peers, Microsoft insiders and industry leaders	https://f.ch9.ms/thumbnail/fbf0a3bf-4e7f-41b3-b178-7dff43353f5e.png
713	http://channel9.msdn.com/Shows/The-Defrag-Show/feed/mp4high	The Defrag Show (HD) - Channel 9	Microsoft	Channel 9's tech support and troubleshooting show hosted by Larry Larsen and Gov Maharaj. Send your questions to DefragShow@Microsoft.com.	http://files.channel9.msdn.com/thumbnail/668139a6-8a4c-4ff0-8b4f-3f3cb9d9de5d.jpg
714	http://channel9.msdn.com/shows/Identity/feed/ipod/	The Id Element (MP4) - Channel 9	Microsoft	In &ldquo;The Id Element&rdquo; show, the Identity Evangelism team introduces you to the fascinating topic of Identity and Access Management. Be sure to visit the The Id Element home page as well.	http://video.ch9.ms/ecn/content/images/IdElement300x300.png
715	http://channel9.msdn.com/shows/PingShow/feed/ipod/	Ping! (MP4) - Channel 9	Microsoft	Mark DeFalco (@MarkDeFalco) and Rick Claus (@RicksterCDN) dish out cool and interesting news based on what Microsofties are pinging each other about over IM, email, Twitter, and Facebook.	http://files.channel9.msdn.com/thumbnail/0d49ebdf-ffbe-4cf9-80ea-ecddc07bb505.png
717	http://channel9.msdn.com/shows/This+Week+On+Channel+9/feed/ipod/	This Week On Channel 9 (MP4) - Channel 9	Microsoft	Every week our TWC9 Hosts go through hundreds of blogs, videos, and announcements to find the most important news in the developer community. Topics include Microsoft .NET development, Visual Studio tips and add-ons, developing for Windows and the Web, and gratuitous gadgets.	https://f.ch9.ms/thumbnail/a704f542-e456-4313-8a05-47b87dbaf0ff.jpg
733	http://chansu.seesaa.net/index20.rdf	Su*のひとり言【podcast】	ERROR: NOT PERMITED METHOD: nickname	mixi日記関連の音声ブログ	\N
734	http://chaoschronicles.libsyn.com/rss	The Chaos Chronicles: Modern Motherhood with a Laugh	Mudbath Productions	Lian Dolan gives her take on modern motherhood and all that includes, from news headlines to parenting observation to advice- giving.	https://ssl-static.libsyn.com/p/assets/f/c/b/7/fcb75b40012500d9/Chaos150x150LOGO_FB.png
735	http://chaosd.podomatic.com/rss2.xml	ChaosD's Asian Rock and Pop	Robert	{Bandwidth Will Reset Around The Beginning Of Each Month. Podcast Lasts About A Week Or So. Just Keep Checking Back}This podcast has mainly Asian rock songs. There is some hip-hop/pop as well. I also have NO CONTROL OVER BANDWIDTH! You just have to listen to it when it resets or donate so I can upgrade bandwidth, it will last a month. http://chaosd.podomatic.com/ is the original podcast page. Email me at rpf20042005@yahoo.com if you have any questions.	https://assets.podomatic.net/ts/f2/b4/d0/chaosd/3000x3000_10629596.jpg
739	http://charadas.podomatic.com/rss2.xml	musica de el salvador	charadas	musica salvadoreña para todos los guanacos de corazon	https://assets.podomatic.net/ts/04/2f/5a/charadas/3000x3000_603805.jpg
746	http://charlestonfirstnazarene.com/feed	Charleston First	\N	Charleston, WV	\N
751	http://chasejarvislive.libsyn.com/rss	The Chase Jarvis LIVE Show	Chase Jarvis	Chase Jarvis is a visionary photographer, artist and entrepreneur. Cited as one of the most influential photographers of the past decade, he is the founder & CEO of CreativeLive. In this show, Chase and some of the world’s top creative entrepreneurs, artists, and celebrities share stories designed to help you gain actionable insights to recognize your passions and achieve your goals.	https://ssl-static.libsyn.com/p/assets/0/a/d/2/0ad257d82cf9526e/20171011_cjLIVE_LSR_Template_3000x3000_v14.2.jpg
752	http://chatnewengland.podomatic.com/rss2.xml	Chat New England Podcast	Nick LaRocque	Every week Nick LaRocque (of www.chatcelts.com) and Ben Babcock (of www.chatpats.com) get together to discuss all the latest Celtics and Patriots news.	https://chatnewengland.podomatic.com/images/default/podcast-4-1400.png
753	http://chaveztofenway.podomatic.com/rss2.xml	From Chavez to Fenway	Daniel Conmy	Shane and Daniel discuss baseball news and problems with the game. We give our opinion from a fans point of view and a former player at the High School level.	https://assets.podomatic.net/ts/08/58/df/chaveztofenway/3000x3000_6855075.jpg
754	http://chavurah.podomatic.com/rss2.xml	Chavurah with Shoshanna	Lillian Boyington	Designed and produced by the The Ministries of www.4Yahweh.org under the direction of Sha'ul Dag and Lillian Boyington	https://chavurah.podomatic.com/images/default/podcast-3-3000.png
755	http://chccs.granicus.com/Podcast.php?view_id=2	Chapel Hill-Carrboro City Schools Board of Education, NC: Chapel Hill-Carrboro City Schools Board of Education Audio Podcast	Chapel Hill-Carrboro City Schools Board of Education, NC		\N
756	http://chccs.granicus.com/VPodcast.php?view_id=2	Chapel Hill-Carrboro City Schools Board of Education, NC: Chapel Hill-Carrboro City Schools Board of Education Video Podcast	Chapel Hill-Carrboro City Schools Board of Education, NC		\N
757	http://chcradio.com/mp3/conversations.xml	Conversations On HealthCare	Community Health Center	Conversations on Health Care is a radio show about the opportunities for reform and innovation in the health care system. In addition to healthcare headlines, each show features conversation with an innovator in the delivery of care from around the globe	http://chcradio.com/mp3/logo.jpg
760	http://cheerfulworld.jellycast.com/podcast/feed/19	Crystal Palace Football Club History With Ian King	cheerfulworld	Crystal Palace FC historian Ian King delves into the archives to bring you fascinating facts about previous encounters between CPFC and their most recent adversaries, looks at famous players from the past, and the highs and lows of our football club.	https://cheerfulworld.jellycast.com/files/palace%20radio%20history%20bitesize.JPG
762	http://chelmsfordsa.podomatic.com/rss2.xml	Chelmsford SA Podcast	ChelmsfordSA	Worship from The Salvation Army, Chelmsford Citadel Corps, Essex, UK	https://assets.podomatic.net/ts/93/60/05/pod55857/3000x3000-352x352+113+0_7174675.jpg
764	http://cheph2000.podomatic.com/rss2.xml	CB LYON'S DANCE ROCK RADIO SHOW	C.B. Lyon	Dance Rock Radio is a blend of rock and dance music, usually both at the same time.  CB Lyon is a world class DJ with destinations such as Ibiza, Tokyo, Paris, London, and travels mostly between New York City and Los Angeles.  If you are into groups like Coldplay, The Killers, Hellogoodbye, Fiest, Young Love, The Klaxons, Panic! At the Disco, The Bravery, The Smashing Pumpkins, Red Hot Chili Peppers, Fall Out Boy, and even Justin Timerlake then this is the perfect place to hear a remix you will never find otherwise.\n                Furthermore if your playlist consists of Justice, Daft Punk, Steve Aoki, Junkie XL, Tommie Sunshine, Peaches, Diplo, Junior Boys, Sebastien Leger, Van She Tech, or Gabriel and Dresden than this podcast is a must.  If you even remotely listen to electro, house, progressive, rock, or club then you will be dancing the moment you hear this!  Simply a must have.  Any mix that CB Lyon does is done with brilliance.  Feel free to email us at lyonecho@gmail.com.  \nIf you want to know a little more about each individual show, here are some details:\nShow #5\nDance Rock Radio is finally back with a long overdue new episode. DRR #5 brings it back to our regular 'Dance Rock' format. CB Lyon absolutely kills it with this mix of wonderful tracks and a few that are virtually impossible to find. It's been a while so enjoy, we'll have the next one on time. This is the tracklist for DRR #5: Athlete - Hurricane (Camp America Remix) Yeah Yeah Yeahs - Cheated Hearts (Peaches Remix) New Young Pony Club - Ice Cream (Comets Remix) Micheal Jackson - Billie Jean (Mathematikal Remix) Fall Out Boy - Dance Dance (Tommie Sunshine Remix) Klaxons - As Above So Below (Justice Remix) Snow Patrol - Open Your Eyes (Walker Remix) Felix da Housecat - Radio The Who - Baba O'Riley (RAC Edit) Ratatat - Seventeen Years (Bacchantae Acapella)\nShow #4\nDance Rock Radio Show #4 is a special show for two reasons. 1) I am doing a special dance 'Rap' episode 2) I am featuring a special guest mix from Atomic Hooligan Tracklist Gym Class Heroes - Clothes Off (Rural Remix) Jay-Z - No Hook (Chew Fu Remix) M.I.A. - Boyz (Twelves Remix) Pharrell ft. Snoop - That Girl (DJA Docs Remix) Hellogoodbye - All of Your Love (Forrests Remix) Lady Tigra - Bass on the Bottom (Justin Kase Edit) Estelle and Kanye West - American Boy Peter, Bjorn, and John - Young Folks (Diplo Remix)\nShow #3\nDance Rock Radio Show #3 starts out with a bang and then follows up with exclusives of groups like the Atomic Hooligans. It's different from the other mixes in that it changes flow and direction at every corner. Enjoy! -CB Lyon This is the track list for DRR 3: Hellogoodbye - All of Your Love (Kimmy Pop Remix) Atomic Hooligans - I Don't Care Shout Out Louds - The Comeback (Big Slippa Remix) The Egg - Nothing (Dusty Kid Loves Rock Remix) Animal Machine - Persona (Para One Remix) Fox N' Wolf - Youth Alcoholic (Etienne De Crecy Remix) Hot Chip - Over and Over Blaqk Audio - Stiff Kittens (Morel's Pink Noise Mix) Sarah McLaughlin - Fumbling Toward Ecstasy (Junior Boys Remix)* -CB *(Sorry McLauglin was misspelled on the podcast as McLachlan\nShow #2\nDRR's second show is a bomb! Full of more amazing tracks you will never hear otherwise from Justice, Daft Punk, Feist, Nine Inch Nails, Alex Gopher, Hard-Fi, Goldfrapp and more! Tracklisting: Justice - D.A.N.C.E. Daft Punk - Human After All (Emperor Machine Remix) Nic Chagall - What You Need (Ncs Prelectric Mix) Feist - 1234 (Van She Remix) Nelson - I Say You Can't Stop (Data Remix) Nine Inch Nails - The Hand That Feeds (DFA Remix) Alex Gopher - The Game Hard-Fi - Suburban Knights (Alex Metric Remix) Goldfrapp - Strict Machine Aphex Twin - Windowlicker\nShow #1\nDance Rock Radio's first installment entitled, Show #1, is a special blend of rock music fused with dance music, lovers of both genres will be elated. It is a smooth mix of dance rock music mixed by C. B. Lyon! Tracklisting: The Killers - Read My Mind (Gabriel and Dresden Remix) (continued)	https://assets.podomatic.net/ts/b6/3b/c6/cheph2000/3000x3000_1858016.jpg
765	http://cherryhillsfamily.org/podcast.xml	Cherry Hills Podcast	Cherry Hills	We’re pursuing life together with Jesus, with one another, and with our community and world.	https://cherryhillsfamily.org/upload/images/Logos/CH_Podcast.jpg
767	http://cherrystreet.podOmatic.com/rss2.xml	Cherry Street  Church of Christ	Cherry Street Church of Christ	The Cherry Street congregation serves New Albany, southern Indiana, and greater Louisville, KY teaching nondenominational, biblical truth with love.	https://assets.podomatic.net/ts/26/11/84/cherrystreet/1400x1400_606717.jpg
770	http://chevron8.podOmatic.com/rss2.xml	Chevron8	Candice	This is my way of honoring THE LONGEST running scifi show out there...Stargate SG-1!  10 years and running y'all!!	https://assets.podomatic.net/ts/69/1c/44/chevron8/1400x1400_604053.jpg
771	http://chewbaxter.podOmatic.com/rss2.xml	chewbaxter's Podcast	Neil Baxter		https://chewbaxter.podomatic.com/images/default/podcast-1-1400.png
772	http://chialphamnsmallgroups.blogspot.com/feeds/posts/default	Chi Alpha MN Small Group Blog/Podcast	Anonymous (noreply@blogger.com)	A dynamic, informative resource for small group leaders, sponsored by Chi Alpha Campus Ministries of Minnesota.	\N
773	http://chicagohousedj.podOmatic.com/rss2.xml	ROCK RE-MIX	Dj MichaelAngelo	Many Different Syle of Mix Sets OF house,Club for more go to \nwww.ChicagoHouseDj.com	https://assets.podomatic.net/ts/30/d2/e2/chicagohousedj/1400x1400_605251.jpg
774	http://chicagohousemusic.podomatic.com/rss2.xml	DJ Z's Podcast (Classic Chicago House Music)	DJ Z	Do you like old school Chicago House Music? Then this podcast is for you. Mixes done by DJ Z of some of your favorite tracks from Chicago's wbmx and B96.Geat house music from the late 80s and early 90s.	https://assets.podomatic.net/ts/38/35/6e/zayaaa/pro/3000x3000_8356491.jpg
778	http://chigov.com/feeds/audio-fb.xml	Inside Chicago Government: Audio Reports and Interviews	Inside Chicago Government	Audio interviews and reports from Inside \nChicago Government.	http://www.chigov.com/images/stories/pcast-chigov-misc.jpg
1041	http://collaborationnationr08.podOmatic.com/rss2.xml	Collaboration Nation R08	Paul Bogush		https://collaborationnationr08.podomatic.com/images/default/podcast-1-1400.png
779	http://chiitownkruger.podomatic.com/rss2.xml	Dirty Beatz	Chiitown Kruger	The Best of Dirty Dutch, if you like Afrojack, Hardwell, Sidney Samson, R3hab, Chuckie, Nicky Romero and many more! Stay locked in right here! New Crazy Mixes with New tracks every Monday and maybe 2 in 1 week, so follow! If it ain't Dutch it ain't much!\nCheck out soundcloud.com/chiitown_kruger	https://assets.podomatic.net/ts/12/6a/04/podcast9307167724/1400x1400_9831703.jpg
781	http://chikitsa.s3.amazonaws.com/podcasts/ttc-podcasts2.xml	TTT 12-13 Recordings	Jeanne Kim	These recordings are lofi, lightly-edited lecture captures intended only for the participants in the TTT12-13.	http://chikitsa.s3.amazonaws.com/podcasts/kevindooleycc.jpg
782	http://chillflavour.podOmatic.com/rss2.xml	chillflavour's Podcast	ignacio molina	Chill-Electronica-Lounge	https://assets.podomatic.net/ts/f2/94/1f/chillflavour/3000x3000_5615999.jpg
784	http://chinanow.podomatic.com/rss2.xml	China Now's Podcast	China Now	“China Now” is a live daily show on China Radio International (CRI). Launched in December 2006, the show aims to showcase the real China to the world, by reporting on Chinese society and culture.\n\nPreviously known as “Beyond Beijing”, which has now become the name of the whole frequency, “China Now” was the first show CRI launched via its overseas FM stations.\n\nChina Now is broadcast live between 2-5 pm Beijing Time, Monday to Friday. Each edition contains more than ten segments, including A Day in the Life, Culture Voyage, Real China, Bookshelf, Blogbite, Expat Tales, Hangout, Chinese Kitchen, and Trend Detective, to name just a few.\n\nWith the variety of segments, up-to-date music and topics of interest to international audiences, the program has drawn many loyal listeners from around the globe. People tune in to hear the latest information and Chinese perspectives as well as finding out about travel tips, cultural aspects and business opportunities in China.\n\nOver the past few years, many reports produced by China Now have won awards for their content. The show itself won the first prize at the 2008 China Journalism Awards, the most prestigious journalism awards in China, claiming the title for “best show”.\n\nChina Now can now be heard in more than a dozen overseas cities, including Nairobi, Canberra, Auckland, Perth, Washington DC, Boston, Phnom Penn and Honolulu. It’s also broadcast online live via cribeyondbeijing.com.	https://assets.podomatic.net/ts/08/80/a2/alex82191/3000x3000_7173835.jpg
785	http://chinapodcast.libsyn.com/rss	NCUSCR Interviews	National Committee on U.S.-China Relations	This series features brief discussions with leading China experts on a range of issues in the U.S.-China relationship, including domestic politics, foreign policy, economics, security, culture, the environment, and areas of global concern. For more interviews, videos, and links to events, visit our website: www.ncuscr.org.\n\nThe National Committee on U.S.-China Relations is the leading nonprofit, nonpartisan organization that encourages understanding of China and the United States among citizens of both countries.	https://ssl-static.libsyn.com/p/assets/0/3/c/9/03c9b1b727a8b1c3/INTERVIEWS.png
788	http://chinoisfacile.podOmatic.com/rss2.xml	chinoisfacile	Angélique Su	Apprendre le chinois avec le podcast "ChinoisFacile". "ChinoisFacile" a été élu parmi les meilleurs podcasts de l’année 2008 tous genres confondus dans l’iTunes Store France. "ChinoisFacile " est une méthode audio d'apprentissage du chinois spécialement conçue pour les francophones, constituée de leçons hebdomadaires de type « podcast » au format MP3, téléchargeables sur ordinateur ou baladeur numérique du type iPod. Elle comprend trois séries de leçons. La  première série "Débutant/ ChinoisFacile" met l’accent sur le chinois parlé et permet aux débutants d’acquérir rapidement les rudiments nécessaires pour mener une conversation courante. Certaines leçons en audio-podcast sont gratuites et disponibles pour téléchargement. D’autres sont disponibles sur demande moyennant une participation aux frais. Le texte intégral des leçons au format PDF, comprenant à la fois la transcription phonétique et les caractères chinois simplifiés, est également disponible sur demande moyennant une participation aux frais. Une seconde série, "Un mot de chinois par jour/ChinoisFacile" est consacrée à l’apprentissage de l’écriture et du vocabulaire. Une troisième série, "Civilisation Chinoise/ChinoisFacile", lancée récemment et élaborée avec Radio Albatros 94.3(http://www.radio-albatros.com) , couvre les traditions, coutumes et cultures dévelopés et préservés en Chine, à Hongkong, Macao, Singapour et Taiwan, ainsi qu’au sein de la diaspora chinoise. Ce podcast est la propriété exclusive d'Angélique SU. Toute utilisation de ce podcast non conforme à sa destination, toute diffusion ou toute publication, totale ou partielle, est interdite sauf autorisation expresse d'Angélique SU ".	https://assets.podomatic.net/ts/49/11/34/chinoisfacile/3000x3000_1130330.jpg
789	http://chinsan.podOmatic.com/rss2.xml	The Immortal Sound Station	Steven Chen	Favorite high quality dance tunes of touching sound selected by myself to create a journey of music, from Progressive, to Trance, House, enjoy the ride!\n\nEmail: chinsan5@hotmail.com\nTwitter: @chin5an\nFacebook: http://www.facebook.com/chin5an\nSina Weibo: http://weibo.com/chin5an	https://assets.podomatic.net/ts/ae/dd/c1/chinsan/3000x3000_4830837.jpg
790	http://chipmonk.podbean.com/feed/	The chipmonk's Podcast			https://djrpnl90t7dii.cloudfront.net/podbean-logo/podbean_58.jpg
791	http://chipmusic.org/music/rss/feed.xml	ChipMusic.org - Music RSS Feed	Chipmusic.org (staff@chipmusic.org)	Music RSS Feed	http://chipmusic.org/forums/img/cast.png
792	http://chiswickcc.podOmatic.com/rss2.xml	Chiswick Christian Centre	Chiswick Christian Centre	Uplifting and inspiring messages to draw you into a deeper intimacy with the Holy Spirit from a dynamic Spirit filled church in London, England. To find out more about our church check our website www.chiswick.cc	https://assets.podomatic.net/ts/07/b7/9e/chiswickcc/3000x3000_14541525.jpg
793	http://chivalrytoday.com/?feed=podcast	Chivalry Today Podcast	scott@chivalrytoday.com (Scott Farrell)	A monthly exploration of the history, literature and philosophy of the code of chivalry - from the code of honor of medieval knights and traditional tales of King Arthur's Round Table, to principles of leadership and ethics in today's business and politics and images of heroes and role models in contemporary media. Hosted by author, independent historian and director of the award-winning Chivalry Today educational program, Scott Farrell.	http://chivalrytoday.com/wp-content/uploads/powerpress/headshotitunes.jpg
794	http://chivkeebbaptist.blogspot.com/feeds/posts/default	chivkeeb baptist church	will (noreply@blogger.com)		\N
795	http://chnpublicmedia.s3-website-us-east-1.amazonaws.com/podcast.xml	Deep in Scripture	Marcus Grodi	All CHN Podcasts Platform	https://podcast.chnetwork.org/wp-content/uploads/2020/03/DIS-series-poster.jpg
796	http://chocolatezombieanddjmcflay.podomatic.com/rss2.xml	The Sound Of Revealed 2014	McFlay	Two DJ/Producer from Hungary and Scotland. DJ Mcflay® (HU) - www.dj-mcflay.tk | Chocolate Zombie (UK) - www.chocolatezombie.co.uk	https://assets.podomatic.net/ts/93/d9/d6/62854/3000x3000_9354427.jpg
797	http://choicelaw.podomatic.com/rss2.xml	Riverside California Foreclosure Attorney	Los Angeles Foreclosure Attorney | 1-866-932-7812	http://www.choicelaw.org - Foreclosure attorneys’ is helping people get out from under their debt burdens.  Let’s face it; going at this alone may not be the best approach.  We understand that the Riverside area has been hit hard by the foreclosure crisis, and we are here to help however we can.  Free Mp3 offering insight to your options.  1-866-932-7812	https://assets.podomatic.net/ts/12/6d/b0/mike85412/3000x3000_4106362.jpg
800	http://chorkorheights.podomatic.com/rss2.xml	PY SAYS SHOW	ChorkorHeights	PY, Ghana's most affable personality, brings you the latest trends in Ghana's music and entertainment industry. The podcast provides insights into the development of various artistes and social activists based in Ghana and the diaspora. You can expect the baddest mixes exclusive to the PY SAYS SHOW! created by DJs on the cutting edge of sound. Co-host Agnes Ntow gives the 411 on the nicest hangouts you can afford as well as reviews and updates on events around town.	https://assets.podomatic.net/ts/de/e7/e0/chorkorheights/3000x3000_8266157.jpg
801	http://choruschurch.sermon.tv/rss/main	The Awakening (Archive)	Kerry Bowman	The Awakening Church	http://storage.sermon.net/9efa6ac006ff5f0a134edb825dd70592/5f954ffe-0-0/content/media/common/artwork/SN-default-1400x1400.png
803	http://chrisandcowboy.podOmatic.com/rss2.xml	Chris Hamblin	Chris and Cowboy	Sports Radio's Chris Hamblin	https://assets.podomatic.net/ts/84/87/3f/chrisandcowboy/1400x1400_12866453.jpg
805	http://chrisandjuan.podomatic.com/rss2.xml	Juan & Chris Podcast	Juan & Chris talk...	Two guys talking about comics, movies, music, arts, tv or just shooting from the hip.	https://chrisandjuan.podomatic.com/images/default/podcast-1-1400.png
806	http://chrisbound.podbean.com/feed/	The Chris Bound Podcast	Chris Bound	News And Opinions From A Disgruntled Mind	https://pbcdn1.podbean.com/imglogo/image-logo/123213/chrisorange.jpg
807	http://chriscaggsradio.podOmatic.com/rss2.xml	ShakeDown Radio Podcast	ShakeDown Radio Podcast	Legendary Radio DJ Chris Caggs Now On Shakedown Radio\n\nIf you go to any major city, you’ll see DJs headlining major concerts, festivals and more, DJs are at the top of the music world in our modern society and Chris Caggs is a force to reckon with in the radio jockeying industry of Australia as he is always in demand; thanks to loyal listeners who can’t get enough of his unique broadcasting techniques wherein he plays a mix of the best Hip-Hop, Dance and RnB tunes.\n\nChris Caggs started his radio career in July 1998 on Sydney’s Pump FM 99.3 in Killara on Sydney’s North Shore – hosting a program with Cameron Griffiths (Mista-C) called “Bedroom Vibes” on a Tuesday Night which consisted of a music format known as Slow Jam RnB on a station to claim themselves as the 1st Hip Hop and RnB Community Station in Australia. The station relaunched as 99.3fm followed in August 2000 Dance FM 94.5FM.\n\nThrough a unique broadcasting techniques that is taking radio broadcasting to a new heights, Shakedown Radio Podcast already debuted as the future of radio broadcasting. \n\nAt the last count, Chris Caggs have featured in over a dozen radio stations;\n\n· Groove FM 94.5FM & 96.9FM - Sydney Metro Wide\n· Groove FM 97.3FM - Brisbane Metro Wide\n· DJ-FM 87.6 Dance Radio - Sydney CBD, Inner Suburbs\n· 2RDJ-FM 88.1FM - Burwood Sydney\n· 2NSB-FM 99.3FM - Northside Radio - Chatswood Sydney\n· Pump FM 99.3FM - North Shore RnB/Dance Radio\n· STR8OUT Radio - Melbourne Dance Station\n· Mix It Up Radio - Brisbane - Talkback & Music Radio\n. ICR Radio - Fairfield Sydney - Urban/Dance\n. Mixxbosses Radio - Sydney - Hip Hop & RnB\n. Urban Movement Radio - Brisbane - Hip Hop & RnB\n. Liquid Radio - Sunshine Coast - Queensland - EDM & House\n. Starter FM - Sydney - EDM & House\n. Tune 1 Perth - EDM & House \n\nINTERVIEWS ARTICLES ON CHRIS CAGGS:\n-North Shore Times\n-The Queensland Independent\n-Scene Magazine Brisbane\n-Three D World Magazine Sydney\n-Revolver Mag\n-Groove ON MEDIA\n-The Music Network\n-Player FM\n-The Place Magazine (North Queensland)\n-Radio Info Newsletter\n-Request Magazine\n\nChris Coggs kick started his 20-year-old career in broadcasting as a radio DJ from 1998 via various Dance and RnB Community Radio Stations located in Sydney and Brisbane. His other interests include music, films, TV, surfing the net, socializing and travelling. He is an avid traveler who has visited 26 countries which include New Zealand, Pacific Islands, Asia, UK and Europe, among others.\n\nMusic Licensed by PLAY MPE www.plaympe.com , Global PR Pool www.globalprpool.com , Relish PR Factory, Platinum Delivery and Five Star Pro	https://i1-static.djpod.com/podcasts/shakedownradiopodcast/52617d_1400x1400.jpg
808	http://chrischonagemeindemornshausen.podspot.de/rss	Podcast Ev. Chrischonagemeinde Mornshausen	Chrischonagemeinde Mornshausen	Predigten als Podcast der Ev Chrischonagemeinde Mornshausen	\N
810	http://chrisdenney.podomatic.com/rss2.xml	Twisted	Chris Denney		https://chrisdenney.podomatic.com/images/default/podcast-1-1400.png
811	http://chrisdoph.podbean.com/feed/	Spanish Word of the Day	www.wordoftheday.es.tt	Every day we will release a new word in Spanish, improving your Spanish vocabulary. Perfect for everyone that is learning Spanish, or is trying to learn a few extra words to use when in South America or Spain.\n\nThis podcast is best for beginners.	https://pbcdn1.podbean.com/imglogo/image-logo/124332/logo.jpg
812	http://chrisdowneypodcast.libsyn.com/rss	The Chris Downey Podcast	Chris Downey	Welcome to “The Downey Files,” a brand new weekly podcast that explores the half baked pitches and movie ideas Chris has scribbled down on beer coasters and cocktails napkins through the years. \n\nEach week, Chris sits down with a new guest to hash out these ideas in full and, you guessed it, hilarity ensues.	https://ssl-static.libsyn.com/p/assets/3/8/6/e/386e9e981cc78152/downeyfiles.jpg
813	http://chriskresser.com/feed/podcast	Revolution Health Radio	chris@chriskresser.com (Chris Kresser)	Revolution Health Radio debunks mainstream myths on nutrition and health and delivers cutting-edge, yet practical information on how to prevent and reverse disease naturally.  This show is brought to you by Chris Kresser, health detective and creator of chriskresser.com.	http://chriskresser.com/wp-content/uploads/RHR-new-cover-lowres.jpg
814	http://chrismurray.podOmatic.com/rss2.xml	DJ Chris Murray	Chris Murray	Balearic mixes / Nu-Disco mixes / Retro House mixes\nmixcloud.com/chrismurray	https://assets.podomatic.net/ts/87/26/f0/chrismurray/1400x1400_5457539.jpg
815	http://chrispillot.podomatic.com/rss2.xml	Chris Coast & Chumpion >> Fast Fwd To The Weekend	Chris Coast & Chumpion >> Fast Forward To The Weekend		https://assets.podomatic.net/ts/d4/a3/41/chrispillot/3000x3000_7615110.jpg
817	http://chrissid.podOmatic.com/rss2.xml	Chrissi D!'s Podcast	Chrissi D!	Artist Info\nDJ CHRISSI D! (Fullrange Rec./SHOWROOM)\nIf you are in love with housemusic there is one DJ you should have in mind: German house music wizard DJ Chrissi D! Chrissi D! is one of the most talented and musically gifted djs around the globe. His unbelievable intuition to set dancefloors on fire by using 3 cd players parallel and keep the crowd rocking for many hours made him popular not only in germany. Many clubbers love his unique style of house music and his incredible qualities as an entertainer behind the decks.\n\n\nOUT NOW:\n- Chrissi D!- Dont you feel - Original/Danny Freakazoid Rmx/Klaas Rmx (Fullrange Rec.) - Farley Jackmaster Funk vs Giorgio Moroder - I wanna rock you- Chrissi D! Remixes (Fullrange Rec.) - Full Intention-I believe in you-Chrissi D! Rmx(Eye Industrie/Kontor)\n- Don Oliver feat Barbara Tucker – Better - Chrissi D! Housebugs Rmx – Milk&Sugar Records.\nCOMING SOON:\n- Chrissi D! - Big in love - (various Mixes)\nReleases & Remixes:\n- Chrissi D! – Don ́t u feel – incl Klaas & Danny Freakazoid Rmxs (Fullrange Rec.) - Full Intention – I believe in u – Chrissi D! Rmx (Eye Industries) - Farley Jackmaster Funk vs Giorgio Moroder - I wanna rock you- Chrissi D! Remixes (Fullrange Rec.) - Da Flavour Inc – Mojito Groove–Chrissi D! Rmx (The official Bacardi Mojito TV Spot Rmx) - Don Oliver feat Barbara Tucker – Better – Chrissi D! Rmx – Milk&Sugar Rec. - Solsonik feat Sabrynnah Pope – In love again – Chrissi D! Housebugs Mix - Tristan da Cunha – Viva Curuba – Chrissi D! Rmx – Concept Rec. - Don Oliver feat Barbara Tucker – Better - Chrissi D! Housebugs Rmx – Villanova Rec. - Erick Morillo feat. Terra Deva – What do you want - Chrissi D! Housebugs Rmxs (Casa Rosso) - Testament – Sunis shining (Chrissi D! Sage Rmx)(Casa Rosso Rec.) - Speakerbox – Hit the Bass – Chrissi D! Rmx (Zyx) - JFK speaks-What you can-(Chrissi D! Rmx) - Bay City Rockerz - Panties wanted – Chrissi D! Rmx. (Casa Rosso) - Milk&Sugars „Let the sun shine in” (Chrissi D! Sunshine at Sage Rmx)(Milk&Sugar Rec.) - Syke  ́n ́Sugarstarr „Ticket 2 Ride“(Casa Rosso Rec./Delicious Garden Rec.) - United DJs of Sage feat. Chrissi D! - Berlin (Sage Records) - Chrissi D! - „ El Nino EP“ (Casa Rosso Rec.) - The Original “I luv u Baby“ incl.– Chrissi D! Rmxs Part 1 ( Skyline Rec. UK) - The Original “I luv u Baby“ incl.– Chrissi D! Rmxs Part 2 ( Skyline Rec. UK)\n\nCD Compilations, compiled&mixed by Chrissi D!:\n\n2012 - Showroom - The Fashion Night (coming soon)\n2010 - Pure Lounging Vol.2 available here: www.soundalacarte.de  \n2008 - Paradise Beach\n2007 – B-LIVE Bacardi Vol.8 (CD 1 by Chrissi D!, CD 2 by Fedde Le Grant) \n2007 – Smag Ibiza Nights 2xCD 2007 - Pure Lounging Vol.1 comp&mixed by Chrissi D! 2005 – Energizing House\n2004 - Ritmo de Bacardi Vol.5 (CD1 Chrissi D!,CD 2 Junior Jack) \n2004 - MTV Battle of the DJs Compilation (2xCD) \n2002 – Malkasten Vol.4 \n2001 – Malkasten Vol.3\n\nwww.chrissid.com \nwww.facebook.com/djchrissid\nwww.instagram.com/djchrissid	https://assets.podomatic.net/ts/8e/33/45/chrissid/pro/3000x3000_10427211.jpg
818	http://chrisstafford.podbean.com/feed/	WiSP Sports	WiSP Sports Corporation	The Voice of Women in Sport	https://pbcdn1.podbean.com/imglogo/image-logo/494945/WiSP_Sports_Podbean_logo8k4nm.jpg
819	http://chrissvargaspodcast.podOmatic.com/rss2.xml	CHRISS VARGAS PODCASTS	CHRISS VARGAS	Favorite NY Colombian DJ \nChriss Vargas Present his \nmonthly Podcast Series	https://assets.podomatic.net/ts/5a/42/57/chrissvargaspodcast/3000x3000_8261156.jpg
820	http://christasus.podbean.com/feed/	Christ in you, the Hope of Glory	Tony Maden	Now in our generation there is a rising \\'voice\\', another wind of the Spirit, speaking one collective Word, which is Paul\\'s \\"mystery hid from ages and generations, which is CHRIST IN YOU. Listen and receive the wonderful rest God has for his children...	https://pbcdn1.podbean.com/imglogo/image-logo/20455/CAU_Podcast_Logoa184x.jpg
823	http://christchurchrolesville.org/feeds/sermons	Sermons	Christ Church Rolesville	Sermons	\N
824	http://christchurchusa.org/podcast/audio_podcast.xml	Christ Church Audio Podcast	Christ Church Media	Christ Church is a non-denominational Christian congregation comprised of people from diverse racial, cultural, and ethnic backgrounds. We are a community minded congregation with a global sensitivity.\n\nChrist Church exists to unite people to God and people to people. The Lord continues to be a source of transformation for every person who comes through our doors.\n\nIt is our hope that your spiritual needs will be met, and that your physical and emotional concerns are addressed as we seek God together through praise and worship.	http://christchurchusa.org/podcast/CC_Audio_Podcast.jpg
825	http://christchurchusa.org/podcast/video_podcast.xml	Christ Church Video Podcast	Christ Church Media	Christ Church is a non-denominational Christian congregation comprised of people from diverse racial, cultural, and ethnic backgrounds. We are a community minded congregation with a global sensitivity.\nChrist Church exists to unite people to God and people to people. The Lord continues to be a source of transformation for every person who comes through our doors.\nIt is our hope that your spiritual needs will be met, and that your physical and emotional concerns are addressed as we seek God together through praise and worship.	http://christchurchusa.org/podcast/CC_Video_Podcast.jpg
827	http://christcommunitycobb.org/feeds/sermons	Media	Staff Member	Media	https://www.csmedia1.com/christcommunitycobb.org/podcast-logo.jpg
888	http://cinemacatnip.podomatic.com/rss2.xml	Cinema Catnip	Ted Evans	Ted Evans, host of Chronicles of Pussy, hosts this podcast with fellow comedian Wayne Burfeind! They along with guests discuss films and the like with no structure whatsoever! (not true)	https://assets.podomatic.net/ts/f7/9e/fb/cinemacatnip/3000x3000_7315315.jpg
829	http://christenlight.podomatic.com/rss2.xml	Christ Enlight II	Craig Bergland	Christ Enlight is a spirituality that understands Jesus' teachings to be wisdom and enlightenment teachings in the spirit of all the great teachers of all traditions.  We seek to transcend the kind of religion that divides us and move instead into an inclusive spirituality that honors all people as bearers of divinity!	https://christenlight.podomatic.com/images/default/podcast-2-1400.png
831	http://christfellowshipeverson.com/feeds/sermons	Sermons	David Steele	Sermons	\N
832	http://christian-gaming.com/category/podcast/hcg-xp-show/feed	Podcast – Christian Gamer	\N		\N
833	http://christianlifechurch.podbean.com/feed/	Christian Life Church	Christian Life Church	Life Changing Series	https://pbcdn1.podbean.com/imglogo/image-logo/32011/LifeChurch.jpg
834	http://christianlifechurchfl.com/podcast/	Christian Life Church Milton, FL	Christian Life Church	Christian Life is a contemporary, creative, life-giving church in Milton, Florida	http://christianlifechurchfl.com/wp-content/themes/clc/img/podcast.jpg
835	http://christianmonotheism.com/podcast.xml	Christian Monotheism Podcast	Christian Monotheism	Listen to lectures, sermons, and debates about who God is from a non-trinitarian perspective.  Get answers to difficult questions and explanations to verses typically used to teach the Trinity.  This is the premier podcast for the biblical unitarian movement including dozens of speakers like Anthony Buzzard, Don Snedeker, Dustin Smith, J. Dan Gill, Joel Hemphill, John Schoenheit, Jonathan Burke, Ken Westby, Kermit Zarley, Patrick Navas, Ray Faircloth, Sean Finnegan, Steve Katsaras, Victor Gluckin, and Vince Finnegan.	http://christianmonotheism.com/images/podcast.jpg
838	http://christification.podOmatic.com/rss2.xml	Christification	Chris Birkett	This is me on my sax, enjoy!	https://assets.podomatic.net/ts/4d/a0/bc/christification/1400x1400_613371.jpg
839	http://christmas.rnn.libsynpro.com/rss	Christmas Old Time Radio	Radio Memories Network LLC	Ho Ho Ho and Merry Christmas! Santa has his sack just packed full of old time radio shows. And if you are good, Santa will be podcasting these heart warming and family fun shows from the Golden Age of Radio.	http://static.libsyn.com/p/assets/5/1/0/d/510d3173c6bac8e5/christmasotr1400.jpg
840	http://christopheravery.podbean.com/feed/	AskChristopherAvery.com Podcast	Christopher Avery Ph.D.	Welcome to the AskChristopherAvery.com podcast where Christopher Avery, the world's leading expert on personal and shared responsibility and author of "Teamwork is an Individual Skill" answers your most burning questions on teamwork, responsible leadership, and agile change. \n\nTo learn more about Christopher Avery Ph.D or his Responsibility Redefined message visit ChristopherAvery.com. \n\nTo ask Christopher a question visit AskChristopherAvery.com and tune into our next LIVE FREE Tele-training.	https://djrpnl90t7dii.cloudfront.net/podbean-logo/podcast_standard_logo_v2.png
842	http://christredeemermn.org/feeds/sermons	Sermons	Thomas Rydland	Sermons	https://www.csmedia1.com/christredeemermn.org/crc_logos-01.jpg
843	http://christschurchguilderland.com/feeds/sermons	Sermons - 672729	Brian Rutherford	Teachings	https://www.csmedia1.com/christschurchguilderland.com/itunes-logo.png
844	http://christt.com/?feed=podcast	Chris T-T's Podcast	Chris T-T	The official podcast series of Chris T-T, UK writer and music maker based in Brighton.	https://christt.com/wp-content/uploads/2014/12/podcast2015.jpg
845	http://christthekingpsl.com/feeds/sermons	Sermons	J.C. Cunningham	Sermons	\N
846	http://christumchurch.podomatic.com/rss2.xml	Christ UM Church Sermons	Christ UM Church		https://christumchurch.podomatic.com/images/default/podcast-2-1400.png
849	http://chroniclesofdrumandbass.podomatic.com/rss2.xml	Saturday Night Vibes Show	Dj Fidjit		https://chroniclesofdrumandbass.podomatic.com/images/default/podcast-4-3000.png
850	http://chroniclesofpussy.podomatic.com/rss2.xml	Chronicles of Pussy	Chronicles of Pussy	Two guys, multiple stories, all wrong. \nWhat do two guys talk about when they get drunk? Failed relationships of course! Join our two hosts as they interview comedians, random bar goers, and every day people male and female on their never ending journey to chronicle personal sexual histories both good and bad. We aren't in Narnia anymore.	https://assets.podomatic.net/ts/04/2b/c4/chroniclesop/3000x3000_7121051.png
854	http://chuckquinley.libsyn.com/rss	Thread Bible Podcast with Chuck Quinley	Thread with Dr. Chuck Quinley	Thread is a verse-by-verse Bible study, God's Word tying together all the pieces of your life.  Find encouragement and direction for your personal life and your ministry to others in each episode of Thread.	https://storage.buzzsprout.com/variants/o8e0dml0s9w9vrq6szv7p8akydcq/8d66eb17bb7d02ca4856ab443a78f2148cafbb129f58a3c81282007c6fe24ff2?.jpg
855	http://church.goodshepherd-elgin.org/sermon.xml	Good Shepherd Lutheran Church, Elgin, IL Sermon Podcast	Good Shepherd Lutheran Church	Worship messages from Good Shepherd Lutheran Church in Elgin, Illinois. Hear the saving message of how Jesus Christ was born, died, and rose for your salvation.	http://church.goodshepherd-elgin.org/img/podcast.png
856	http://churchaliveag.libsyn.com/rss	Church Alive - Fuquay Varina, NC	Church Alive	Church Alive Weekly Sermons	https://ssl-static.libsyn.com/p/assets/3/2/d/e/32deef84a8341ee4/CA_Podcast_Logo_-_Official.jpg
860	http://churchnextdooraz.com/feed/podcast/	The Church Next Door – AZ	scottmitchell1975@gmail.com (Scott Mitchell)	The Church Next Door is a missional church in Prescott Valley, AZ, working with local churches to share Jesus and love our community in tangible ways.  Find out more at churchnextdooraz.com.	http://churchnextdooraz.com/wp-content/uploads/2013/01/CND-w-city-square.jpg
861	http://churchofchriststm.org/podcastblaster.xml	church of Christ St Marys, GA	www.churchofchriststm.org	Sermons and other audio from the church of Christ in St Marys, Georgia	podcast.jpg
864	http://churchofthekingmcallen.org/sermons/cotk-rss/	Faith of our Fathers Broadcast	Church of the King - McAllen, TX	Sermons from Church of the King, located in McAllen Texas, A Non-denominational Evangelical Church, Our motto is "On to the future with the faith of our fathers!" By "fathers" we are referring to the historical church, the Reformers, and the Puritans. They believed God is sovereign.	http://churchofthekingmcallen.org/wp-content/uploads/2019/09/COTK-new-album-artwork.jpg
889	http://cinemadeboteco.podomatic.com/rss2.xml	Sessão Boteco	Sessão Boteco	Três roteiristas fazem um Podcast sobre Cinema diretamente de uma mesa de Bar. www.sessaoboteco.com.br	https://assets.podomatic.net/ts/c9/58/b5/cinemadeboteco/3000x3000_9855669.jpg
890	http://cinemajaw.com/wordpress/?feed=rss2	CinemaJaw	mattkubinski@yahoo.com (Matt K & Ry The Movie Guy)	CinemaJaw is: Movie News, Reviews, and Interviews. Movie Trivia, Nostalgia, and Mania. Segments include: Top 5 Lists, Hollywood Headlines and much more. Plus the best guests from all over the map! <br />\n<br />\nCinemaJaw is people jawin' about movies (hence the name), and who doesn't love that topic? It's funny, opinionated and entertaining as hell!	http://cinemajaw.com/wordpress/wp-content/uploads/powerpress/CinemaJaw2015Logo.jpg
865	http://churchoftruthandspirit.podOmatic.com/rss2.xml	Online Church - Church Of Truth And Spirit	Cityside Ministries International	It's Not In A Building But In The Building Of The Body!\nWelcome to the true Church which is you , your Spirit meeting with us in Spirit.   Eph 4:11 - says. To equip the saints for the purpose of ministry. So that they are sent out so they can do their part for the Body Of Christ.\n\n\nWe are all called to do God's work in one way or another, we will not hold you , after you have listened the segments/sermons  and you have learned the things we teach you. If you need in the land, we will give you a certificate (but only under God) so you may go  the spread the gospel and do the work of an Evangelist like Paul said in 2 Timothy. \n\n\\We all are called to be leaders  and servants in the word and bring up others as we are brought under Christ Jesus and to prepare us for the New Jerusalem. As Spirits this is why we peculiar creatures in this land. We are not about money as many are but not all church building leaders are because we believe God will provide for us as he did Christ (Remember the money in the fishes mouth), the word of God says God loves a cheerful giver and to give without being under compulsion. You are not bind down to tithe with us (We d not believe in it as it's old covenant ordinances) based on this scripture. If you choose to give an offering this is up to you and please allow the Holy Spirit to lead you in this.\n\nIf you are: (Go to: www.citysidemusicministries.com/donations ) and God will bless you accordingly to his word. \nThank you for taking this short time to view our introduction and we welcome you as online church members to the true Body (In Spirit) of Christ.\n\nGod Blesses With Spiritual Love!\nking Stevian\nApostle, Pastor, Teacher	https://assets.podomatic.net/ts/66/6a/49/churchoftruthandspirit/3000x3000_2332780.jpg
868	http://churchsoblessed.podomatic.com/rss2.xml	Church So Blessed	Church So Blessed	www.churchsoblessed.org	https://assets.podomatic.net/ts/ef/7d/3a/churchsoblessedmedia/pro/3000x3000_14231049.jpg
869	http://churchstate.org/index.php?id=325	Freedom's Ring Podcast	Church State Council	Freedom’s Ring Radio is a nationally syndicated w…	http://i1.sndcdn.com/avatars-000131579666-c1ybz1-original.jpg
870	http://chutneyradio.com/podcasts/DaS/dholmasti.xml	Dhol Masti with Da "S"   ---   www.ChutneyRadio.com	Sunil@chutneyradio.com (Sunil)	Dhol Masti is a show all about the Bhangra beats whether they be remix\n\t\tor pure.  Most of the songs have a strong dhol beat in them but there\n\t\tare others played that are slow punjabi songs beautiful in nature.\n\t\tThe show is produced by me Sunil (aka Da S) but the music is all about\n\t\tthe people.	http://www.chutneyradio.com/podcasts/DaS/chutneyradio.jpg
871	http://chuyamartinez.podomatic.com/rss2.xml	LIBRE POR SU GRACIA	Pastor William Garcia		https://chuyamartinez.podomatic.com/images/default/podcast-2-1400.png
872	http://chynawhyte.podomatic.com/rss2.xml	Chyna Whyte	Chyna Whyte	DOWNLOAD CHYNA WHYTE ON EVERY SITE ON THE INTERNET NOW.  \nChyna Whyte, a rhyme poet, best known for her power-packed performance on Lil Jon & the Eastside Boys classic club banger and Billboard charted song Bia Bia, has been in the music industry writing and recording for more than 16 years. Born Stephanie Christine Lewis in New Orleans, La., signed her first recording contract with BME Records in 1999 and in 2001 signed a distribution deal with TVT Records. Although her accolades are many, they were not fulfilling her deep passion for meaning, for change, for happiness, for truth. Her way of life became a burden so she made a change. She humbled herself before God and allowed him to transform her and when he changed her heart, her message in her music changed.\n\nNow with the world still eagerly awaiting her debut LP, Chyna with the help of Jesus has re-invented her image and her life and has stepped into one of her calls, entrepreneurship. She started WhyteHowse Entertainment, LLC in 2006 but has recently by the direction of the Holy Spirit brought to the forefront Abraham's Seed Music Force, LLC which will be a force to be reckoned with. She also has been a BMI writer and publisher, Ching Chong Publishing, since 1997. People need God, they want him, they are searching for him and not even know it. People need to know that God is the answer, that he is real and that he is the TRUTH, the true rider as we say in street terms. I want them to know the truth about the industry and the things that they think are real are not and that life, the riches, the glamour, the fame that they are lusting for is nothing without God. I don’t want them to get caught up into the hype because that’s all that it is. I’m ready to bust hell wide open on earth, to expose the enemy and to show people to the light which is Jesus Christ. I want the young kids and adults, really everybody that’s hurting and looking for answers to know that everything that they want and need is in Jesus Christ.\n       Latest tracks by Chyna Whyte	https://assets.podomatic.net/ts/f7/7e/65/chynawhytemusic/3000x3000_3698906.jpg
873	http://cia.libsyn.com/rss	Zenprov	Marshall Stern and Nancy Howland Walker	Marshall Stern and Nancy Howland Walker host a series of podcasts about the art of Improvisational Acting in general and Zenprov, how Zen thought relates and helps you as an actor,  in particular.	https://ssl-static.libsyn.com/p/assets/8/6/c/0/86c0c0b12a93a3da/Zenprov_Business_CardBackVertical.jpg
874	http://cia.mistral.csphares.qc.ca/?feed=podcast	Le Comité des Informateurs Avertis	Le Comité des Informateurs Avertis		http://cia.mistral.csphares.qc.ca/wp-content/uploads/powerpress/podcast1.png
875	http://cia.podbean.com/feed/	The Culinary Institute of America	Videos from The Culinary Institute of America	Explore endless menu possibilities with videos from the Chefs from The Culinary Institute of America.  Recipes and more videos online at www.CIAprochef.com.	https://pbcdn1.podbean.com/imglogo/image-logo/2573/cialogo.jpg
878	http://cicministry.org/audio/radio/cic_radio.xml	Critical Issues Commentary Radio	Critical Issues Commentary	Critical Issues Commentatry grew out of Bob DeWaay's passion to equip the saints for the work of ministry. In the late 1980's Bob met regularly with a group of local pastors, often presenting position papers on timely doctrinal issues. When he found that the messages were accepted by only a few of the attendees and rarely reached the pews, he chose to speak directly to the people by initiating a bimonthly newletter.\n\nBob DeWaay is teacher and theologian at Gospel of Grace Fellowship in Edina, MN. Gospel of Grace Fellowship can be found on the web at http://www.gospelofgracefellowship.org/ where you can listen to sermons and other teachings.\n\nFor more information on Critical Issues Commentary or to read CIC articles, visit Critical Issues Commentary on the web at https://cicministry.org/	https://cicministry.org/images/CICPodcastLogo.jpg
882	http://cinderbiter.podomatic.com/rss2.xml	Dimwit	Kyle Doerksen		https://assets.podomatic.net/ts/33/34/5a/cinderbiterpodcast/1400x1400_11288739.jpg
887	http://cinema.podfm.ru/rss/rss.xml	Бесславные Кинокритики	PodFM.ru	"Бесславные Кинокритики" — еженедельная программа  о новинках кинопроката и новостях киноиндустрии. Руководители Дома Культуры поселка Ропша Ленинградской области по выходным устраивают бесплатные кинопоказы, после которых разбирают по косточкам премьеру недели, анализируют киноновости и вспоминают киностарости. Теперь они выходят на межгалактический уровень.	http://file2.podfm.ru/9/96/968/9686/images/lent_10806_big_52.jpg
915	http://cityofnorthport.granicus.com/Podcast.php?view_id=6	North Port, FL: Governing Bodies Audio Podcast	North Port, FL		http://admin-101.granicus.com/Content/Northport/North_Port_Video_Podcasting.jpg
892	http://cinemascope.libsyn.com/rss	CinemaScope	KSFR	Cinema Scope focuses on the film, TV and media industry in New Mexico, but it is not just for industry professionals. Host Nazneen Akhtar Rahim presents a variety of lively interviews, news and reviews.	https://ssl-static.libsyn.com/p/assets/0/0/7/9/0079183f3da4a7df/Cinema_Scope_W_Nazneen_Logo.png
893	http://cinvestav-dg.podomatic.com/rss2.xml	Podcast Cinvestav - D.G.	Valente Espinosa	Boletín Electrónico de la Dirección General del Centro de Investigación y de Estudios Avanzados del I.P.N.	https://assets.podomatic.net/ts/7b/ae/10/cinvestav-dg/1400x1400_1410010.png
894	http://cipodcast.libsyn.com/rss	Competitive Intelligence Podcast	August Jackson	The Competitive Intelligence Podcast is produced to further the professional practice of competitive intelligence and serve as a vehicle for the sharing of best practices within the community. Each episode consists of a mix of news, overview of recent and upcoming events of interest and discussions of specific research methods or other such topics of interest.	http://static.libsyn.com/p/assets/e/9/8/5/e9852a894227ad6a/CIPodcastiTunes.jpg
895	http://cippo.hu/podcast.xml	Magánszám	Cippo	színes, szélesvásznú, szövegelős játszótér	https://www.cippo.hu/wp-content/uploads/2019/06/mszpodcastprofil.jpg
896	http://citadel.libsyn.com/rss	Citadel GrayLine	Colonel Rall Media, LLC	The weekly radio show and podcast on Citadel Bulldog Sports	https://ssl-static.libsyn.com/p/assets/6/1/d/b/61dbc917950ad7a7/CG_Podcast_Logo.png
899	http://citrusonic.libsyn.com/rss	Drum and Bass Dubstep IDM EDM DNB | Hip Hop Beats | Reaktor Midi Synthesizer | Sound Design & License  | Computer Music Live | Computers LIVE | Hardcore Breakcore Techno	Citrusonic	Computer Music Live / Citrusonic is a weekly podcast dedicated to Live Computer Music Performances. This show features Live Underground Jungle, Techno, DNB, Hip Hop, Dubstep, Future, Noise, Synth, Trance, Pop, DJ, Mixing, Battle, Records, Music, Altering, AM, FM, Modulations, Radio, Computer, Harmonies. Thunderous Scratch-Tracks, Techno, Glitches, Old, Skool, Breaks, Ejects, iDose, Chaos and Bass. An hour long podcast of Fresh Original Electronic Dance Music. Menacing Cantus Firmus Basslines, Heavyweight Drums and Synthesizers all LIVE! Computer Music Live is posted every Saturday Night from California, only the hottest Underground Jungle Music is chosen. New podcasts are posted on a weekly basis and up to the minute show information is here http://citrusonic.libsyn.com/ and you may also visit www.citrusonic.com for more. Thank you and make sure to tell all your friends to subscribe to Computer Music Live.	https://ssl-static.libsyn.com/p/assets/c/9/3/b/c93b007131b45078/ComputerMusicLive2013ComputerMusic.jpg
901	http://citycentral.libsyn.com/rss	City Central Church Podcast	City Central, Tacoma WA	City Central Church is a place where followers of Jesus Christ seek God's power and presence by adoring the Savior, becoming more like Him and contending for His kingdom. Based in Tacoma, Washington, City Central seeks to share the good news about Jesus with those who are lost, bring restoration and healing to those who are broken and build up and train the saints of God. This podcast features sermons originally delivered at City Central Church in Tacoma during Sunday morning worship services. A few highlighted midweek teachings are included as well. Lead Pastor Chris Hippe preaches the majority of the Sunday morning sermons. Occasional guest messages are delivered by City Central staff members or friends of the ministry. Sermon series notes, links and processing questions can be found in the Resources section of the City Central Church website. God is moving in the city of Tacoma! Join us as we dive into God's Word and seek to know Him more intimately and experience greater depths of His truth and love. If you are listening to this podcast from out of town and have any plans to visit the Puget Sound area, stop by Sixth Avenue in Tacoma and pay us a visit at City Central.	https://ssl-static.libsyn.com/p/assets/d/9/1/5/d915d2604246fac8/CC_Square_Large.png
904	http://citylife.podOmatic.com/rss2.xml	CityLife Church, New Plymouth, NZ	CityLife Church	CityLife Church consists of people whose lives have been transformed by God’s love and power through a vibrant relationship with Jesus Christ. \n\nOur mission is to see ‘Generations and Nations. Loving God and Loving People’ and our aim is to communicate God’s love to others in many and varied ways.\n\nDISCLAIMER: Opinions or thoughts shared on this platform are the Speakers’ own and may not be wholly representative of Citylife Church and it’s views and values. If you have concerns’ or feedback on any messages shared on this platform, please contact: admin@citylife.org.nz	https://assets.podomatic.net/ts/57/fc/c4/citylife/3000x3000_12447489.jpg
905	http://citylightsnc.podomatic.com/rss2.xml	City Lights Bookstore	City Lights Bookstore NC	http://www.citylightsnc.com/\n\nCity Lights Bookstore\n\nEvents and author readings	https://assets.podomatic.net/ts/a1/72/f5/more30758/0x0_7504522.jpg
907	http://cityofedgewater.granicus.com/Podcast.php?view_id=2	City of Edgewater, FL: New View Audio Podcast	City of Edgewater, FL		http://admin-101.granicus.com/content/cityofedgewater/podcastImage/edge.jpg
908	http://cityofedgewater.granicus.com/vPodcast.php?view_id=2	City of Edgewater, FL: New View Video Podcast	City of Edgewater, FL		http://admin-101.granicus.com/content/cityofedgewater/podcastImage/edge.jpg
909	http://cityoflegends.com/TheRomanticPoetoftheInternet.xml	The Romantic Poet of the Internet	William F DeVault	The poetry of William F. DeVault, one of the fathers of the digital renaissance.	http://www.cityoflegends.com/300wfdv.jpg
911	http://cityofnorthport.granicus.com/Podcast.php?view_id=2	North Port, FL: City Commission-orig Audio Podcast	North Port, FL		http://admin-101.granicus.com/Content/Northport/North_Port_Video_Podcasting.jpg
912	http://cityofnorthport.granicus.com/Podcast.php?view_id=3	North Port, FL: City Commission Audio Podcast	North Port, FL		http://admin-101.granicus.com/Content/Northport/North_Port_Video_Podcasting.jpg
913	http://cityofnorthport.granicus.com/Podcast.php?view_id=4	North Port, FL: North Port Presents: The View From Here Audio Podcast	North Port, FL		http://admin-101.granicus.com/Content/Northport/North_Port_Video_Podcasting.jpg
914	http://cityofnorthport.granicus.com/Podcast.php?view_id=5	North Port, FL: Special Programming Audio Podcast	North Port, FL		http://admin-101.granicus.com/Content/Northport/North_Port_Video_Podcasting.jpg
920	http://cityofpalmdesert.granicus.com/vPodcast.php?view_id=2	City of Palm Desert, CA: Default View Video Podcast	City of Palm Desert, CA		http://admin-101.granicus.com/content/cityofpalmdesert/images/podcastImage/cityofpalmedesert.jpg
922	http://citytrex.com/feeds/buckwalterradio.xml	Buckwalter Radio	CityTrex	Developer Matt Green talks business with local insiders of the South Carolina and Georgia Lowcountry (USA). A production of CityTrex LLC by Burton Sauls. - All Rights Reserved -	http://static.libsyn.com/p/assets/8/9/3/b/893bfff7f36a4853/height_150_width_150_BuckwalterRadioLogo_LOGO_Aug1_.jpg
923	http://cityview.podomatic.com/rss2.xml	City View PodCast	City View SportsCast	Covering all things Youngstown, Ohio sports including Youngstown State Penguin athletics, Mount Union Purple Raiders athletics, OHSAA sports, Youngstown Phantom Hockey, Mahoning Valley Scrappers, and more.	https://assets.podomatic.net/ts/4d/3c/d7/b-whan/3000x3000_7816556.jpg
925	http://civilmediationcouncil.jellycast.com/podcast/feed/5	Living Mediation 2013 Conference	civilmediationcouncil	The Civil Mediation council Conference was held at the Senate House, University of London. The Board welcomed The Reverend Mpho Tutu as the keynote speaker and Peter Adler who gave the afternoon keynote. Vice Chair, Bill Wood QC lead a discussion about the CMC's consultation exercise on registration/accreditation of individual mediators and mediation training providers. More details and a consultation form is available on the civilmediation.org web site. A wide range of conversations with practitioners new and seasoned and interviews with The Reverend Mpho Tutu, Peter Adler, Sir Alan Ward the new CMC Chair and Jon Siddall, the new CEO.\n\nThanks all who were involved in the creation of the conference: members of the conference committee, the communications committee and our conference organiser, David Richbell.	https://civilmediationcouncil.jellycast.com/files/Living-Mediation-Podcast.png
926	http://civitella.podbean.com/feed/	Civitella	Civitella Ranieri	Civitella Ranieri is an artist residency program located in Umbertide, Italy	https://pbcdn1.podbean.com/imglogo/image-logo/344658/civitellapic.jpg
927	http://cj-tw1.seesaa.net/index20.rdf	トワイライトエクスプレス・ポッドキャスティング	中嶋茂夫	トワイライトエクスプレスの車内放送、駅放送を公開しています。	http://cj-tw1.up.seesaa.net/image/podcast_artwork.jpg
930	http://cjpeeton.podOmatic.com/rss2.xml	Cj Peeton - Range of Emotions	Cj Peeton	Cj Peeton - Range of Emotions	https://assets.podomatic.net/ts/38/7a/eb/cjpeeton/1400x1400_8210304.jpg
931	http://cjplive.podomatic.com/rss2.xml	Combined Jewish Philanthropies	CJP Live	Videos from Combined Jewish Philanthropies. Footage from Boston, Israel, and around the world, featuring our volunteers and highlighting our priorities.	https://assets.podomatic.net/ts/c9/09/fc/telisad/3000x3000_7710555.jpg
932	http://cjromb.com/podcasts/glow/glow_in_the_dark.rss	Glow In The Dark	CJ Romberger	Glow in the Dark is a collection of poems and essays from my heart, which is sometimes broken. http://bit.ly/itcjromb	http://cjromb.com/podcasts/glow/images/glow_in_the_dark.jpg
935	http://cktl.fr/podcast/podcast.xml	CKTL music	Mortimer Valla	CKTL est un groupe multiforme né dans les années 80. Le StudioGL présente au fur et à mesure dans ce podcast l'activité actuelle de CKTL : Remix de morceaux anciens (CKTL-R), nouvelles chanson des sections CKTL-VTS et CKTL-F.	http://cktl.fr/podcast/podcastImage.jpg
936	http://clarence-cc.squarespace.com/podcast-feed?format=rss	Sermon Podcast Feed - Clarence Church of Christ	Mike Bowers	Clarence Church of Christ, Clarence. NY. Find us on-line at http://www.ClarenceCC.org	https://images.squarespace-cdn.com/content/50a45c82e4b000dda4d932b2/1358135983657-Z2I1JBPRBW55OW8UM4U9/CCC-Logo-July-2012-Podcast-Logo-2400.jpg?format=1500w&content-type=image%2Fjpeg
939	http://clarkesworldmagazine.com/?feed=podcast	Clarkesworld Magazine - Science Fiction & Fantasy	Clarkesworld	Science fiction and fantasy stories from Clarkesworld, a Hugo and World Fantasy Award-winning digital magazine. Stories from Clarkesworld  have been nominated for or won the Hugo, Nebula, World Fantasy, Sturgeon, Locus, BSFA, Ditmar, Aurora, Shirley Jackson, WSFA Small Press and Stoker Awards.	http://clarkesworldmagazine.com/wp-content/plugins/podpress/images/powered_by_podpress.jpg
941	http://clasicosdeljazz.podomatic.com/rss2.xml	Clásicos del Jazz (por Memo Man)	Memo Man	Breves anécdotas de los músicos que marcaron la historia del jazz. Cápsulas escritas y producidas desde México DF.	https://assets.podomatic.net/ts/c5/e6/97/guitarraxs/3000x3000_4950908.jpg
942	http://classical959.podbean.com/feed/	Classical 95.9-FM WCRI	Classical 95.9-FM WCRI	Programming from Classical 95.9 WCRI: Conducting Conversations, Jazz After Dinner, & WCRI's Festival Series, WCRI's Classical Kids Hour and more	https://pbcdn1.podbean.com/imglogo/image-logo/58630/wcri_600x600_trans.png
944	http://classichousemixes.podOmatic.com/rss2.xml	classichousemixes's Podcast	DEEP SOULFUL VOCAL HOUSE PODCASTS NEW AND CLASSIC - SCOTT MILLER - HEAR NO	OVER 25 DEEP,SOULFUL,VOCAL,GOSPEL,CLASSIC TO FRESH QUALITY HOUSE MUSIC MIXES AND PODCASTS. YOU CAN SUBSCRIBE THROUGH ITUNES AND GOOGLE ETC AND KEEP UP TO DATE AND GET EACH NEW PODCAST AS THIER UPLOADED\n'HEAR NO EVIL' IT'S ALL IN THE MUSIC!   PEACE.. \nhttp://classichousemixes.podomatic.com/\n\nfor more hearnoevil mixes visit djrossmiller.podomatic.com	https://classichousemixes.podomatic.com/images/default/C-3000.png
945	http://classicpoetryaloud.podOmatic.com/rss2.xml	Classic Poetry Aloud	Classic Poetry Aloud	Classic Poetry Aloud gives voice to poetry through podcast recordings of the great poems of the past. Our library of poems is intended as a resource for anyone interested in reading and listening to poetry. For us, it's all about the listening, and how hearing a poem can make it more accessible, as well as heightening its emotional impact.\nSee more at: www.classicpoetryaloud.com	https://assets.podomatic.net/ts/8f/62/80/classicpoetryaloud/3000x3000_615237.jpg
947	http://classictales.libsyn.com/rss	The Classic Tales Podcast	B.J. Harrison	Every week, join award-winning narrator B.J. Harrison as he narrates the greatest stories the world has ever known. From the jungles of South America to the Mississippi Delta, from Victorian England to the sands of the Arabian desert, join us on a fantastic journey through the words of the world's greatest authors. Critically-acclaimed and highly recommended for anyone who loves a good story with plenty of substance.	https://ssl-static.libsyn.com/p/assets/c/e/6/1/ce61e91decd27ef5/CT-Podcast-Logo-2019Spotify.jpg
948	http://classreaction.libsyn.com/rss	Class Re-Action Podcast	H. Scott Leviant	With guest panels comprised of experienced attorneys and judges, this podcast analyzes recent events in class action litigation and related law fields.  Topics of discussion include recent decisions, new laws, arbitration, consumer law, wage & hour law, and coming trends.	https://ssl-static.libsyn.com/p/assets/0/8/0/d/080d577f33969fe7/PodcastCover7-SL-LH.jpg
975	http://clockworkcoconut.podbean.com/feed/	Clockwork Coconut	Dr. J.T. Wesley and R. Scruffy Gomer	Steampunk Podcast for the Orlando Area.\nHosted by Dr. J.T. Wesley\nwith sidekick and Man Thursday, R. Scruffy Gomer	https://pbcdn1.podbean.com/imglogo/image-logo/511000/CCPdLE.jpg
949	http://classycareergirl.libsyn.com/rss	The Classy Career Girl Podcast	Anna Runyan	Welcome to The Classy Career Girl Podcast, hosted by Anna Runyan, founder and CEO of Classy Career Girl, named by Forbes as one of the top 35 most influential career sites. Anna Runyan is a former corporate consultant turned entrepreneur and each week she brings you inspiring lessons to help you find career fulfillment, work life balance and happiness so you are ready for the incredible impact that you can make on the world. Let's begin today's class with Classy Career Girl.	https://ssl-static.libsyn.com/p/assets/b/f/a/6/bfa645c227692e0a/2019_CCG_Podcast_Cover.png
951	http://claycup.com/podcast/tt/tt.xml	Truth Talk	Jason Dennett	"The purpose for "Truth-Talk 832" is taken from the words of the greatest thinker, teacher, and leader that has ever lived, Jesus of Nazareth.  In John 8:32Jesus said "And you shall know the Truth, and the Truth shall set you free."  \n\n"Truth-Talk 832" seeks to spread the Truth of God's Word as found in the Old and New Testament scriptures, in the hopes of setting people free by coming to know the Saviour of the world, Jesus Christ, the God-Man.\n\n"Truth-Talk 832" is a Bible teaching ministry of Pastor Jason Dennett, the Teaching Pastor of Calvary Chapel of Puerto Rico.  For more information, please visit www.calvarychapelpuertorico.com or Pastor J's apologetic site - www.intelligentfaith315.com.  You can also search for the podcast "Intelligent Faith" on Itunes, along with "Reason To Believe."	http://claycup.com/podcast/tt/ttlogo.png
952	http://clayesmore.jellycast.com/podcast/feed/6	Clayesmore English Literature at AS and A2 level	clayesmore	For students preparing to take exams or submit coursework in English Literature at AS and A2 level. This is a series of short (10 - 15 minute) talks about major texts or ideas met on the course. It is generally assumed that listeners will have a copy of the text to hand, but this is not essential.	https://clayesmore.jellycast.com/files/Logo%20AS%20and%20A2v2_0.jpg
953	http://clcaudio.jellycast.com/podcast/feed/4	Christian Life Church PM Sermons	clcaudio	We hope you enjoy the audio from our evening services at Christian Life Church, Chambersburg, PA. We are located at 1400 Warm Spring Road. Joe Pickens, Sr. Pastor.	https://clcaudio.jellycast.com/files/pmsermons.jpg
955	http://clccatskill.sermon.tv/rss/main	Community Life Church of Catskill NY	Richard Snowden	Sunday Messages from Community Life Church	http://storage.sermon.net/7aa62dd8c718214b74540d7db11369c4/0-0-0/content/media/22682/artwork/22682_93_podcast.jpg
958	http://clearaction.podOmatic.com/rss2.xml	Improving Customer Experience	Lynn Hunsaker	ClearAction is a customer experience consulting firm specializing in mentoring executives for customer-focused innovation, business process improvement and customer relationship skill development. ClearAction emphasizes customer hassle prevention for greater results in customer retention and profitability. See www.ClearAction.biz	https://assets.podomatic.net/ts/b9/aa/cb/clearaction/3000x3000_1408076.jpg
961	http://client.pixelworkshop.com/HoCoMoJo/podcast.xml	HoCoMoJo Podcasts	Dave Bittner	People, politics and punditry! Dennis Lane and Paul Skalny bring their unique perspective to Howard County news and events.	\N
962	http://cliff.libsyn.com/rss	Nothing But The Blues	Cliff Mcknight	Nothing but the blues, from the earliest to the latest, all genres	https://ssl-static.libsyn.com/p/assets/a/4/a/0/a4a02d06eb4ed3e5/nbtb.jpg
963	http://cliffandkendall.podbean.com/feed/	Cliff and Kendall: Coast 2 Coast	Cliff and Kendall	Cliff and Kendall are covering the topics others are too scared or possibly too busy to! There are countdowns, scripted specials, freaky facts, weird news, bad jokes, perfect pitch, best friends, special guests, and more!	https://pbcdn1.podbean.com/imglogo/image-logo/218891/ck_classic_orange_upd.jpg
964	http://cliffyburrows.podomatic.com/rss2.xml	Progressive Roads	Clifton Burrows	Bringing you the best the Progressive scene has to offer!	https://assets.podomatic.net/ts/73/08/f4/cliffyburrows/3000x3000_13946255.jpg
966	http://clinically.inane.us/feed/podcast/	Clinically Inane	rhinosaur@gmail.com (Clinically Inane)	Hosts Curtis & BoetW sit down weekly to discuss geek news, ridiculousness in the world, movies, music, games, and occasionally have a guest.	http://clinically.inane.us/wordpress/wp-content/uploads/2015/06/Cover-Update.jpg
967	http://clinicalmicro.podOmatic.com/rss2.xml	Clinical Micro's Podcast	Clinical Micro		https://clinicalmicro.podomatic.com/images/default/podcast-4-3000.png
968	http://clintcast.com/assets/feeds/Clintcast.rss	Clintcast	Maun-Lemke Speaking and Consulting, LLC	Clintcast brings Clint Maun's innovation and expertise to you via podcast. Clint is nationally recognized for his innovative leadership in healthcare consulting, speaking and research. In under 15 minutes, you'll hear healthcare's best practice stories, tips and anecdotes five days a week. Join us for Clint's unique "twist" on healthcare which is fun, motivational and offers immediately usable ideas!	http://www.clintcast.com/feeds/Clintcast.jpg
969	http://clintcrisher.podOmatic.com/rss2.xml	Clint Crisher Radio	Clint Crisher	A mixture of Clint Crisher live performance videos, celebrity interviews and dance remix album projects with house, electro and disco moving your body... Clint Crisher Radio is dedicated to bring you the best dance acts from around the world. Please visit the website at http://clintcrisher.podomatic.com	https://assets.podomatic.net/ts/2e/8e/f9/clintcrisher/0x0_9928281.jpg
970	http://clinvestments.com/wordpress/feed/podcast/	The Market Bull	Caleb Lawrence	Market commentary without the usual Wall Street spin.	http://clinvestments.com/wp-content/uploads/2018/07/ITunesHorns.jpg
971	http://clipcast.libsyn.com/rss	ClipCast. The Best Clippers Podcast	Overtime Media	The Best Clippers Podcast. ClipCast is the longest running Clippers podcast ever. Hosted by Chris Kawhild AKA Chris Wylde and Henry Dittman AKA Burbank Hank. The guys interview Clippers, Clipper fans, Clips reporters and Clipper celebrities. Sound the horn! Overtime Media; Your Sport. Your Team. On your time. Overtime is a Sports Podcast Network covering Pro and College Sports leagues and teams with entertaining and insightful podcasts.	https://images.megaphone.fm/s9k6CriOH_weY80DQvotAoxMlemjapD3SAeEkY2Jupw/plain/s3://megaphone-prod/podcasts/18dce55e-ca7a-11e9-a364-cb4da09e88e8/image/uploads_2F1567622757475-dgv0pj6rvx9-a4095f923f67c4b35dfc2957356aae2a_2FClipCast_OT.jpg
973	http://clivebarkercast.podomatic.com/rss2.xml	The Clive Barker Podcast	Ryan Danhauser	A podcast about Clive Barker and the folks at Occupy Midian.	https://ssl-static.libsyn.com/p/assets/4/8/3/3/4833c8017d7a3ef6/1400x1400_7438741.jpg
974	http://cliveparnell.jellycast.com/podcast/feed/2	Bono Loves Grace - What is Grace all about? a series of talks looking at what the bible says into todays culture	cliveparnell	Clive Parnell is a speaker and singer-songwriter.\nHe used to play in the band Indigoecho and is now in a band/collective called The mystery tent.\nwww.myspace.com/themysterytent\nThis podcast looks at what the bible says today. Can it speak into our culture? Can we learn more of who God is?	https://cliveparnell.jellycast.com/files/bono.jpg
980	http://cloudnine.podomatic.com/rss2.xml	Digital Groovebox	Cloud9	The ultimate in Dance Music. This podcast has an array of musical styles including (but not limited to): trance, progressive, tech house, techno, tribal & house. Stay tuned for future episodes with great music mixed by our very own Cloud9 dj's Tek & Flux and guest dj's. Keep it locked right here!!!	https://cloudnine.podomatic.com/images/default/podcast-3-3000.png
983	http://clu-in.org/live/archive.xml	Contaminated Site Clean-Up Information (CLU-IN): Internet Seminar Audio Archives	Contaminated Site Clean-Up Information (CLU-IN) (webmaster@emsus.com)	Audio archives of internet seminars offered through the Contaminated Site Clean-Up Information (CLU-IN) website	https://clu-in.org/images/podcast/sun_for_podcast.jpg
984	http://club-fg-live.podomatic.com/rss2.xml	Club FG Live	DJ Polo	l'émission ou sont rassemblé les meilleurs DJs résident FG	https://assets.podomatic.net/ts/4e/6a/27/gaga524513504/3000x3000_5589495.jpg
985	http://club-fg-suerstar.podomatic.com/rss2.xml	Club FG superstar: David Guetta et Benny Benassi	DJ Polo	Tous les soirs les meilleurs DJs viennent mixés sur FG	https://assets.podomatic.net/ts/19/63/83/podcast69210/3000x3000_5625425.jpg
987	http://clubgriffin.podOmatic.com/rss2.xml	JL Griffin's Podcast	JL Griffin		https://clubgriffin.podomatic.com/images/default/podcast-2-3000.png
988	http://clubliv.libsyn.com/rss	Club Liv Podcast	Club Liv	Club Liv presents it's official podcast series, featuring world-renowned EDM artist's that play at the venue located on the Gold Coast, Australia. Subscribe to this podcast and visit www.livnightclub.com.au for all upcoming events	https://ssl-static.libsyn.com/p/assets/d/f/8/d/df8d0229a1041b3d/LivPodcastMix.jpg
989	http://clubmoralstocklist.podomatic.com/rss2.xml	Club Moral Stocklist	Club Moral Stocklist	The Club Moral Stocklist as of nr. CM001	https://clubmoralstocklist.podomatic.com/images/default/podcast-2-1400.png
990	http://clubpenguinmusic.podOmatic.com/rss2.xml	Club Penguin Music	Roller005 j	Cool music herd on club penguin	https://assets.podomatic.net/ts/2f/ea/f6/clubpenguinmusic/1400x1400_613166.jpg
991	http://clubpenguinnews.podomatic.com/rss2.xml	Club Penguin News	Pufflecatcher	Club Penguin News is the news podcast that airs on Wednesdays bringing all the news from The Penguin Times and the CP blog, not to mention many extras!\nThe podcast should come out on Wednesday nights with additional breaking newscasts and PSAs!	https://assets.podomatic.net/ts/a5/d5/7f/clubpenguinnews/1400x1400_608055.jpg
993	http://clubwave.podomatic.com/rss2.xml	Beat Players	Beat Players	www.clubwave.hu\nwww.facebook.com/beatplayershun	https://assets.podomatic.net/ts/2c/b6/8e/web1243/3000x3000_9144107.jpg
996	http://cmbuzz.podomatic.com/rss2.xml	CM Buzz	Keith Tusing		https://assets.podomatic.net/ts/05/6e/d8/keith19014/1400x1400_3460436.png
998	http://cmedge.wordpress.com/feed/	CM Edge	\N	giving you what you need to stay current and relevant and on the edge of of children’s ministry	https://secure.gravatar.com/blavatar/86db66c055860884add4cc797d0b5b7e?s=96&d=https%3A%2F%2Fs0.wp.com%2Fi%2Fbuttonw-com.png
999	http://cmmayo.podomatic.com/rss2.xml	C.M. Mayo's Podcast (Marfa Mondays & More)	C.M. Mayo	Award-winning travel writer and novelist C.M. Mayo hosts several podcast series here: "Conversations with Other Writers"; "Marfa Mondays: Exploring Marfa, Texas & Environs in 24 Podcasts 2012-2013"; "Podcasts for Writers," and more.	https://assets.podomatic.net/ts/e7/12/ea/cmmayo/pro/3000x3000_4784661.jpg
1001	http://cmro.travis-starnes.com/podcast_feed.xml	Complete Marvel Reading Order Podcast	Travis Starnes	Four podcasts dedicated to the Complete Marvel Reading Order, both of which talk about major events and individual issues from the history of Marvel Comics starting at the silver age (FF #1) and moving forward. CMRO Podcasts is from the proprietors of the site and covers all issues in the Main 616 order, as well as a lot of history and backstory of what was going on in the comic world when those issues came out. Disorderly Conduct skips to just the important issues and includes a couple of regular contributors and visiting members of the site. Fueled by a little alcohol and a lot of fun.  Avengers Inspirations is a chat between a father and a daughter about the comics that inspiried the Marvel movies.  Highway 616 is a three time weekly podcast by CMRO editor Maidel, as he examines the latest marvel comics while on his way to work.	http://cmro.travis-starnes.com/images/podcast_logo.jpg
1003	http://cms1.proximedia.com/files/27849/MediaArchive/07-08/podcast/fc-brusselspodcast.xml	FC Brussels Podcast	FC Brussels	Via deze Podcast kan u makkelijk op de hoogte blijven en de nieuwe interviews snel downloaden - Ecoutez les dernières interviews du site www.fc-brussels.be	http://cms1.proximedia.com/files/27849/MediaArchive/img/fcbrusselspodcast.gif
1004	http://cn4ft5.wordpress.com/feed/	cn to the blue	\N	cnblue n ftisland rock	https://secure.gravatar.com/blavatar/3ecd8105fe365efb81d636818cc0c00a?s=96&d=https%3A%2F%2Fs0.wp.com%2Fi%2Fbuttonw-com.png
1005	http://cni.libsyn.com/rss	Comic News Insider	Joe Gonzalez	The podcast for everything comic book, animation, sci-fi and pop culture. Hosted by Jimmy Aquino & a rotating panel of co-hosts, CNI is your weekly dose of industry news, reviews and interviews. \n\nPast guests include: Stan Lee, John Romita, Sr., Jerry Robinson, Brian K. Vaughan, Ed Brubaker, Matt Fraction, John Cassaday, Paul Pope, Darwyne Cooke, JM Dematteis, Steve Niles, Garth Ennis, Steve Rude, Kyle Baker, Jim Lee, James Jean, Alison Bechdel, Arthur Suydam, Jonathan Hickman, Greg Pak, John McCrea, Zoe Bell, Ted Raimi, David Tennant, Russel T. Davies, Felicia Day, Seth Green, Rob Zombie, Brian Pulido, Olivia Munn, Michael Rooker, Ben Templesmith, Kate Beaton, Faith Erin Hicks, Amber MacArthur, Seth Meyers, Joss Whedon, Nathan Fillion, Bryan Fuller, Kristin Chenoweth, Rosario Dawson, Olivia D'Abo, Patton Oswalt, Tom Kenny, Michael Emerson, Kevin Pereira, Paul Cornell, Jackson Publick, Doc Hammer, Molly Crabapple, and Blair Butler (G4TV). \n\nCNI, the "Entertainment Weekly" of comic podcasts, continues to bring the fun and the funny! (Hey, it's better than being the "US Weekly" of comic podcasts.) Join Jimmy every Wednesday to laugh, learn and maybe even love!\n\nCreated & Produced by Joe Gonzalez	https://ssl-static.libsyn.com/p/assets/5/7/5/7/5757684ee70e0001/CNI2010Logo_600_copy.jpg
1006	http://cnlo.wordpress.com/category/podcasts/feed/	Podcasts – Chapel Next Linden Oaks, FT Bragg NC	\N	Loving God...Connecting with Others...Advancing the Kingdom!	https://secure.gravatar.com/blavatar/ea1cbacbc05c98fa83c25f629f477672?s=96&d=https%3A%2F%2Fs0.wp.com%2Fi%2Fbuttonw-com.png
1038	http://colinsmith.adobetv.libsynpro.com/nano	No Stupid Questions with Colin Smith	Adobe TV	Adobe expert Colin Smith answers the questions he is constantly asked on the road as he educates people in the world of Adobe video and design software.	http://static.libsyn.com/p/assets/d/5/0/5/d50548952c3c76d9/Logo.jpg
1039	http://colinsmith.adobetv.libsynpro.com/rss	No Stupid Questions with Colin Smith	Adobe TV	Adobe expert Colin Smith answers the questions he is constantly asked on the road as he educates people in the world of Adobe video and design software.	http://static.libsyn.com/p/assets/d/5/0/5/d50548952c3c76d9/Logo.jpg
1007	http://cnx2022.podomatic.com/rss2.xml	Más que un Carpintero-PodCasts de Chris	Mr. C	En esta serie de Podcasts, estaremos estudiando la veracidad de Jesucristo mediante este excelente libro llamado: Más Que Un Carpintero, por Josh McDowell.\nReligiones van y vienen. Nunca falta aquella religión que un "profeta" vino y añadió o modificó la Biblia y la gente sin pensarlo bien, siguen aquellas religiones. Pero, si se puede comprobar que Jesús sí existió, y fue lo que Él dijo, entonces no hay manera que la Biblia pueda ser modificada como muchos han intentado de hacerlo. El que escuche esto, sabrá que Jesús no es un personaje en el que se cree por "fe". El camino de Dios es para pensarlo y aceptar con una mente racional, lógica y crítica con base a la evidencia de Jesús y la Biblia. No es de aceptar solo por que un "predicador" le dijo que así era.\n\nPara más audios, visiten mi blog:\n\nwww.lasmentirasdelaevolucion.blogspot.com	https://assets.podomatic.net/ts/ca/c4/43/cnx2022/3000x3000_3299324.jpg
1010	http://coaching.podspot.de/rss	Coaching	systargo Ltd&CoKG	Coaching tritt in vielen Kleider auf, häufig sinnvoll, zeitweise aber auch ?in des Kaisers neuen Kleidern". Seien es die vielfältigen Formen des Coachings, sei es der Wildwuchs des Marktes oder der Konzepte hinter den Coachingansätzen: Wir sorgen für Klar-Darstellung! Natürlich beschreiben wir auch Praxisfälle und haben Übungen und Tipps für Sie. \r\nDanke, dass wir Ihr Coach sein dürfen!	\N
1011	http://coachjoebeer.macmate.me/JBST/SMARTcast/rss.xml	CoachJoeBeer helps you train for Triathlon, Duathlon, Ironman, Sportive, Time-trial and running events	J.Beer - JBST.com	Since 2006 Coach Joe Beer and various side-kicks, guests &amp; athletes have given training, nutrition &amp; technology advice to improve your triathlon, duathlon, Ironman, running &amp; cycling performances. Visit these great brands www.Nopinz.com  www.SouthForkRacing.co.uk and www.ForthEdge.co.uk	http://coachjoebeer.macmate.me/JBST/SMARTcast/SMARTcast_files/COACHJOEBEER.jpg
1014	http://coasterradio.libsyn.com/rss	CoasterRadio.com: The Original Theme Park Podcast	Mike Collins	A weekly podcast dedicated to theme parks, roller coasters and thrill rides.\n\nDuring each show, we talk about the total theme park experience.  We'll have interviews with the people making decisions at your favorite park, reviews and ratings of the newest rides and attractions, discussion about everyday park experiences and chances to win tickets and merchandise from parks around the country!	https://ssl-static.libsyn.com/p/assets/c/2/2/d/c22d557a4db6e614/CR_1400_itunes.jpg
1015	http://coastfm.org.au/feeds/coastfm963.xml	Coast FM 963 - Central Coast NSW Australia	Garth Weiley	Coast FM 963 - Podcast Feature broadcast and web only programs from Coast FM 963. www.coastfm.org.au	http://www.coastfm.org.au/coastfm-pcast-logo.jpg
1016	http://cocaj.ru/idnb/idnbfeed.xml	iDnB podcast	Coca J	Monthly podcast devoted to non-commercial Intelligent Drum and Bass music, inslusive of: atmospheric, liquid funk, minimal, neurodeep, sambass, soulful, techmospheric and others of this kind with slight distractions to downtempo, nu jazz and deep dubstep. Consists of the best releases of past month, brilliantly mixed. Voiceless versions available as well. Enjoy!	http://cocaj.ru/idnb/idnbpodcast_logo.jpg
1018	http://cocoringo.wordpress.com/feed/	Cocoringo's Circadian Sounds: Ethiopian Edition	\N	Give us this day our "daily" song	https://secure.gravatar.com/blavatar/568b8b38a507079c9f6790ded6b6a83f?s=96&d=https%3A%2F%2Fs0.wp.com%2Fi%2Fbuttonw-com.png
1020	http://code3fightclub.podbean.com/feed/	Code 3 Fight Club Radio	Code 3 Fight Club	Connecting you to the awesome world of Mixed martial arts! Fighter interviews! Promotion updates & reviews!	https://pbcdn1.podbean.com/imglogo/image-logo/4412/C3FCAirwaveskiller.jpg
1021	http://codytalksshow.podomatic.com/rss2.xml	Cody Heitschmidt's Podcast	CodyTalks.com		https://codytalksshow.podomatic.com/images/default/podcast-4-3000.png
1022	http://coffee-and-milk.seesaa.net/index20.rdf	コーヒーと牛乳	りえ	ちょっとビターなぐっさんと、まろやかテイストなりえがつくったら、こんなラジオになりました。	\N
1023	http://coffeeandmarkets.com/feed/podcast/	Coffee and Markets	bdomenech@gmail.com (Coffee and Markets)	Coffee and Markets is a daily podcast on markets, politics, and the economy from New Ledger Radio. Hosted by Brad Jackson, Coffee and Markets features Wall Street veteran Francis Cianfrocca and appears on Redstate.	http://coffeeandmarkets.com/wp-content/uploads/powerpress/facebooklogo.png
1024	http://coffeewithkenobi.libsyn.com/rss	Coffee With Kenobi: Star Wars Discussion, Analysis, and Rhetoric	Dan Zehr	Coffee With Kenobi is your spoiler-free place for Star Wars discussion, analysis, and rhetoric. Join Dan Z and a bevy of guests as they explore the mythology of Star Wars from a place of intelligence and humor. This is the podcast you're looking for!	https://d1bm3dmew779uf.cloudfront.net/rss/show/3271982/c98eadb5b8e99f0fa1be8c2cc7b741b3.jpg
1026	http://cogop.sermon.tv/rss/main	Church of God of Prophecy	Church of God of Prophecy	Sermons and teachings provided by the COGOP International Offices.	http://storage.sermon.net/9bb382b26f0c60e080fd66c6dc66b17e/0-0-0/content/media/22241/artwork/22241_8_podcast.jpg
1027	http://cohinr.podomatic.com/rss2.xml	House Funky Electro Podcasts	KaiMan's PodCast	http://itunes.apple.com/gb/podcast/kave-mans-podcast/id419584272	https://assets.podomatic.net/ts/fc/35/9f/cohinr/3000x3000_3865817.jpg
1029	http://coleccionsw.libsyn.com/rss	COLECCION STAR WARS HASBRO MEXICO	Pegamento Producciones	Podcast independiente con noticias y novedades sobre la entrañable línea de colecionables de Star Wars de Hasbro en México. Con un énfasis especial en las figuras de acción. Fechas de lanzamiento, promociones especiales, cápsulas históricas, preguntas y respuestas y guía de figuras con información oficial de Hasbro México.	https://ssl-static.libsyn.com/p/assets/7/0/7/1/70718c3da74638d7/CSWHM_Logo_1.jpg
1032	http://coletti.co.uk/kp/krautpod.xml	Uncle Pauly's Krautpods	Paul C	An irreverent peek into the latest (and not-so-latest) bands, acts and artists of Germany's thriving music scene.	http://coletti.co.uk/kp/up-pod-pic.jpg
1034	http://colinandjosh.podbean.com/feed/	Colin and Josh in the Morning	Colin and Josh	Come join Colin and Josh every Tuesday and Thursday Mornings live from Texas Java Coffee House!!!	https://pbcdn1.podbean.com/imglogo/image-logo/121703/ColinandJosh.jpg
1036	http://colinmarshall.libsyn.com/rss	Notebook on Cities and Culture	Colin Marshall	(Formerly The Marketplace of Ideas.) A world-traveling interview show where Colin Marshall sits down for in-depth conversations with cultural creators, internationalists, and observers of the urban scene about the work they do and the world cities they do it in, from Los Angeles to Osaka to Mexico City to London to Seoul and beyond.	https://ssl-static.libsyn.com/p/assets/f/6/1/e/f61eb190c2c2b5ee/ncclogo.jpg
1037	http://colinsmith.adobetv.libsynpro.com/iphone	No Stupid Questions with Colin Smith	Adobe TV	Adobe expert Colin Smith answers the questions he is constantly asked on the road as he educates people in the world of Adobe video and design software.	http://static.libsyn.com/p/assets/d/5/0/5/d50548952c3c76d9/Logo.jpg
1042	http://collaborationnations08.podOmatic.com/rss2.xml	Collaboration Nation S08	Paul Bogush		https://collaborationnations08.podomatic.com/images/default/podcast-3-1400.png
1043	http://collectionscanada.gc.ca/obj/800001/f11/BAC-Balado-m4a-f.xml	Découvrez Bibliothèque et Archives Canada	Bibliothèque et Archives Canada	Le balado Découvrez Bibliothèque et Archives Canada est l'endroit où l’histoire, la littérature et la culture canadiennes vous attendent. Chaque mois, nous allons vous présenter les trésors de notre collection, vous guider à travers nos nombreux services et vous présenter aux gens qui acquièrent, préservent et font connaître le patrimoine documentaire canadien.	http://www.collectionscanada.gc.ca/obj/800001/f1/Avatar_2020_FR.jpg
1044	http://collectionscanada.gc.ca/obj/800001/f11/LAC-Podcast-m4a-e.xml	Discover Library and Archives Canada	Library and Archives Canada	The Discover Library and Archives Canada podcast is where Canadian history, literature and culture await you. Each month, we will showcase treasures from our vaults, guide you through our many services and introduce you to the people who acquire, safeguard and make known Canada’s documentary heritage.	http://www.collectionscanada.gc.ca/obj/800001/f1/Avatar_2020_EN.jpg
1046	http://collegechurch.org/podcast.cfm	College Church of the Nazarene University Avenue Podcast	College Church of the Nazarene University Avenue	These are the podcasts available from College Church of the Nazarene University Avenue. Bourbonnais, IL	https://faithconnector.s3.amazonaws.com/collegechurch/images/library/podcastimage.jpg
1048	http://collegenewsnc.podomatic.com/rss2.xml	College News North Carolina	J.D. Angel	Starting in August of 2008 College News North Carolina will be on Itunes giving the latest North Carolina College News	https://assets.podomatic.net/ts/d3/6b/56/collegenewsnc/1400x1400_1094278.png
1049	http://collegepark.ws/service.rss	College Park Baptist Church	Rick Matthews	Sunday worship services, College Park Baptist Church.	http://www.collegeparkbaptist.org/Visitors/ChurchFront.jpg
1051	http://collinsport.net/?feed=rss2	Collinsport	Collinsport	Just another WordPress site	http://collinsport.net/wp-content/plugins/powerpress/rss_default.jpg
1052	http://collotype.podOmatic.com/rss2.xml	Collotype: The Podcast!	Collotype	This is the audio version of my blog, found at http://collotype.blogspot.com\nI am full of useful information, and biting sarcasm.	https://assets.podomatic.net/ts/e3/df/20/collotype/3000x3000_2007914.jpg
1057	http://comainevent.libsyn.com/rss	The Co-Main Event MMA Podcast	Chad Dundas	An irreverent and unscripted look at the week's mixed martial arts news from The Athletic's Ben Fowlkes and Chad Dundas. Topics include the latest happenings in the UFC, Bellator and other promotions.	https://ssl-static.libsyn.com/p/assets/f/1/c/0/f1c083218ac9fe86/logo3x.png
1058	http://combaterock.podomatic.com/rss2.xml	combate rock	mgaia		https://combaterock.podomatic.com/images/default/podcast-4-3000.png
1059	http://comeandreason.com/podcasts/2008_comeandreason_biblestudyclass_itunes.xml	Come And Reason 2008:  Bible Study Class	Dr. Tim Jennings	The Come and Reason Bible study class meets Saturday mornings at 10:15am on the campus of Southern Adventist University, Collegedale, TN (18 miles east of Chattanooga).  Class participants discuss topical subjects of the Bible and about the true character of God.  75-100 people from late teens up to retirees attend the class taught by Dr. Tim Jennings and other members of the class from time-to-time.	http://comeandreason.com/images/MP3_AlbumArt_144.jpg
1060	http://comeandreason.com/podcasts/2009_comeandreason_biblestudyclass_itunes.xml	Come And Reason 2009:  Bible Study Class	Dr. Tim Jennings	The Come and Reason Bible study class meets Saturday mornings at 10:15am in the Seminar Room of Collegedale SDA Church on the campus of Southern Adventist University, Collegedale, TN (18 miles east of Chattanooga).  Class participants discuss topical subjects of the Bible and about the true character of God.  Up to 160 people from late teens up to retirees attend the class taught by Dr. Tim Jennings (and other members of the class from time-to-time).	http://comeandreason.com/images/MP3_AlbumArt.jpg
1061	http://comeandreason.com/podcasts/2010_comeandreason_bsc_itunes.xml	Come And Reason 2010:  Bible Study Class	Tim Jennings, MD	The Come and Reason Bible study class, taught by Dr. Tim Jennings, discusses topical subjects of the Bible and the true character of God.	http://comeandreason.com/images/MP3_AlbumArt3_144.jpg
1062	http://comeandreason.com/podcasts/2011_comeandreason_bsc_itunes.xml	Come And Reason 2011:  Bible Study Class	Tim Jennings, MD	Come and Reason Ministries conducts a Bible study class, taught by Dr. Tim Jennings, that discusses topical subjects of the Bible and the true character of God.	http://comeandreason.com/images/MP3_AlbumArt3_144.jpg
1063	http://comeandreason.com/podcasts/2012_comeandreason_bsc_itunes.xml	Come And Reason 2012:  Bible Study Class	Tim Jennings, MD	Come and Reason Ministries' Bible study class, taught by Dr. Tim Jennings, that discusses topical subjects of the Bible and the true character of God.	http://comeandreason.com/images/MP3_AlbumArt3_144.jpg
1064	http://comediaagogo.libsyn.com/rss	Comedia A Go-Go's Public Axis	Comedia A Go-Go	San Antonio's award winning sketch comedy troupe touch your topics inappropriately with their live and at-home comedy podcast!	https://ssl-static.libsyn.com/p/assets/3/c/b/5/3cb5226292500973/Public_Axis_600x600_Info_Logo.jpg
1065	http://comediansatlaw.podomatic.com/rss2.xml	The Comedians at Law Podcast	The Comedians at Law Podcast	The official podcast of Comedians at Law.  Discussing current events, legal issues, law school and entertainment all through the eyes and ears of four lawyers turned stand up comedians.  Check them out at www.ComediansatLaw.com\n\nAnd follow Comedians at Law on Twitter (@ComediansatLaw) and use the hashtag #CALPod each week to send questions to be read and answered on the show.	https://assets.podomatic.net/ts/d8/df/52/comediansatlaw/0x0_9038950.jpg
1067	http://comedyfilmnerds.libsyn.com/rss	Comedy Film Nerds	Comedy Film Nerds	Movie reviews by stand-up comics and filmmakers Graham Elwood and Chris Mancini	https://ssl-static.libsyn.com/p/assets/6/6/3/8/66383810916f2339/Comedy_Film_Nerds_logo.jpg
1070	http://comedypros.libsyn.com/rss	Comedy Pros	Brian Carter	Interviews with improv people, comedians, storytellers and more. This podcast is about: 1. How do you get better? 2. Where do people get stuck and how do they overcome obstacles? 3. How do you make a living?	https://ssl-static.libsyn.com/p/assets/3/1/9/3/319351bc42c7bfb8/CPSQ.png
1071	http://comeweb.podOmatic.com/rss2.xml	comeweb Risorse	Romolo Pranzetti	Risorse web e software per l'educazione	https://assets.podomatic.net/ts/27/fd/2f/comeweb/3000x3000_605380.gif
1138	http://conscb.podbean.com/feed/	Zahra: Indian Ayurveda, Biotech & Beyond		Zahra covers the Indian Lifesciences landscape. Not just regular pharma, but also Biotech, Ayurveda and anything to do with LIFE!	https://pbcdn1.podbean.com/imglogo/image-logo/87590/logo.jpg
1575	http://dasylva.podomatic.com/rss2.xml	DA SYLVA podcast (www.dasylva.fr)	DA SYLVA (www.dasylva.fr)	Booking: dasylvadj@gmail.com / Info: www.dasylva.fr	https://assets.podomatic.net/ts/0d/e0/8c/djdsmix/3000x3000_13170976.jpg
1072	http://comicalradio.wm.wizzard.tv/rss	Comical Radio	Comical Radio	Broadcasting since 2005 Comical Radio is series of shows hosted by Danny Lobell and Chris Iacono recorded out of New York, Denver, and L.A. The Comical Radio Network features exclusive interviews with the world's top stand-up comedians and celebrity guests, original programming, comedy news, and hilarious comedy sketches. Past guests have included. George Carlin, Kid Rock, Paul Giamatti, Henry Winkler, Chris Rock, Jackie Mason, Colin Quinn, Seth MacFarlane, and many more. Visit the website at www.ComicalRadio.com	http://static.libsyn.com/p/assets/3/2/1/4/3214c56604c82291/Comical-Radio-album-art-1400x1400.jpg
1073	http://comicbookattic.libsyn.com/rss	The Comic Book Attic	Michael Pindell	In this podcast, I talk about the wide, wonderful world of comic books, mostly from days gone by.	https://ssl-static.libsyn.com/p/assets/7/5/3/0/75308db6f3d3030c/cba.jpg
1074	http://comicbookclublive.com/?feed=podcast	Comic Book Club	comicbookclublive@gmail.com (Comic Book Club)	Comic Book Club is a LIVE weekly talk show about comic books in New York City, every Tuesday night at 8pm! Hosted by Justin Tyler, Pete LePage, and Alex Zalben, we welcome the best guests from the world of comics and comedy every week!	http://comicbookclublive.com/wp-content/uploads/powerpress/comic-book-club-logo-podcast-3000x3000.jpg
1076	http://comicbooksavant.libsyn.com/rss	Comic Book Savant-The podcast for the serious comics fan.	\N		\N
1078	http://comicconspiracy.libsyn.com/rss	The Comic Conspiracy	Ryan Scott	Marvel rules! DC rules! Or maybe they don't, depending on the week! From the producers of The Geekbox comes The Comic Conspiracy, a weekly podcast about all things good (and bad) in the four-color world of comics, hosted by Ryan Higgins, Brock Sager, Toby Sidler, and Charlie West. New episode every Tuesday night!	https://ssl-static.libsyn.com/p/assets/f/a/f/9/faf9fa585bc06229/ComicConspiracy-iTunes-icon-1500x1500.jpg
1081	http://comicsaregreat.com/?feed=comicsaregreat	Comics Are Great!	jerzydrozd@gmail.com (Jerzy Drozd)	Jerzy Drozd talks with various comics creators from all walks, discussing what makes comics such a great medium.	http://comicsaregreat.com/images/cag_albumart_1400.jpg
1082	http://comicsinhell.libsyn.com/rss	Comic Books Are Burning In Hell	Tucker Stone	The only podcast about comic books on the internet, with Joe McCulloch, Chris Mautner, Matt Seneca and Tucker Stone.	https://ssl-static.libsyn.com/p/assets/6/0/9/1/6091ea9b842bc8ff/comicbooksareburninginhelllogo_3000x3000_compressed.png
1084	http://comicsonline.com/podcast.rss	ComicsOnline	Kevin Gaussoin (podcast@comicsonline.com)	ComicsOnline Podcast is hosted by ComicsOnline Editor-in-Chief Kevin Gaussoin and Co-Hosts Dune Murderous, Mike Lunsford and Troy-David Phillips, and features a revolving panel of regular and guest podcasters. We discuss everything including and tangential to Comics, TV, Movies, DVDs, Blu-ray discs, Video Games, and Technology. ComicsOnline is EVERYTHING geek pop culture.	http://www.comicsonline.com/COP/COPlogo.jpg
1085	http://comingtoamericabaseball.com/feed/podcast/	Coming to America Baseball	psricc@gmail.com (ComingToAmericaBaseball.com)	The only podcast from Asia talking about baseball around the Pacific-Rim (in English), pop culture and our own personal lives.  Learn about some off-base baseball topics from around the Pacific Rim.   <br />\n<br />\n<br />\n<br />\n<br />\n<br />\n<br />\n<br />\n<br />\n<br />\n<br />\n<br />\n<br />\n<br />	http://comingtoamericabaseball.com/wp-content/uploads/powerpress/ctabb_1_font.jpg
1088	http://commandcontrolpower.com/podcast?format=rss	Command Control Power: Apple Tech Support & Business Talk	PsiMac	Sam, Jerry, and Joe discuss their thoughts and draw from their combined experience of over 20 years in the Apple Consultants Network (ACN).	https://images.squarespace-cdn.com/content/51cb8456e4b043b66a2477ae/1517535965266-3GHOSJNSEFIE2MOLR1OJ/Cmd-Ctrl-pwer+logo+black+on+white+cover+art.png?content-type=image%2Fpng
1091	http://commercialinvestingcenter.hartmannetwork.libsynpro.com/rss	The Commercial Investing Show	Jason Hartman	MHPListings Podcast	http://static.libsyn.com/p/assets/3/9/1/a/391a985fbb065e59/Commercial_Investing_Show_Itunes_with_Jason.jpg
1092	http://commoflage.heltperfekt.com/feed/podcast/	Commoflage	cacctus@hotmail.com (Commoflage)	Commoflage är en svensk podcast som spelar SID-musik från Commodore 64, och C64-remixar. Mitt namn är Henrik Andersson, jag är 4X år och växte upp med en härligt beige Commodore 64 och dess ljud. För mig lever SID-musiken fortfarande kvar. Ofta bisitter Anders Hesselbom och ser till att sunket hålls till ett minimum!<br />	http://commoflage.heltperfekt.com/wp-content/uploads/powerpress/Commoflage_1400.jpg
1093	http://commonentrancers.podbean.com/feed/	Common Entrance RS	www.ce-rs.com	Podcasts to help pupils to prepare for Common Entrance Religious Studies exams.  These are my summaries of the Set Texts.  For more information, and for a wide selection of revision resources, visit www.ce-rs.com.	https://pbcdn1.podbean.com/imglogo/image-logo/341717/Logo2.jpg
1095	http://commonsenseatheism.com/wcif.rss	Why Christianity is False	Luke Muehlhauser	Quick responses to essays by Christian apologists.	http://commonsenseatheism.com/wp-content/uploads/2010/08/wcif-logo.png
1105	http://communitybroadcast.podomatic.com/rss2.xml	Community Broadcast, Fridays @ Artisan Night Club Las Vegas	Steve Christmas	Community is currently on hiatus. Las Vegas, NV deep techno and underground house music night that was held every Sunday at The Artisan Botique Hotel, downtown, Las Vegas. \nDedicated and seasoned taste-makers in the underground life style, Jeremiah Green (AZ), Steve Walker (LV), Steve Christmas (LV), and Rob Dub (LV) join forces to save Las Vegas from drowning in a sea of 'cheesy EDM at mega clubs in the city.' \n\nPartnering with a collective of the envelope-pushers local to Las Vegas, the nation, and around the world, our residents contribute to the forthcoming rise of Las Vegas as a hot bed for underground dance music and the lasting development it exudes. \n\nThank you all for your continued support through the infancy of our event. We promise to come back when you least expect it. \n\nhttps://www.facebook.com/groups/CommunitySundays	https://communitybroadcast.podomatic.com/images/default/podcast-3-3000.png
1107	http://commuterknitter.libsyn.com/rss	Commuter Knitter Podcast	Jennifer D (ndjen04)	Where the Yarn Meets the Road\nJen is a knitter.  She is a commuter. And she podcasts about knitting as she commutes.  Come along for the ride!\nndjen04 on Ravelry; CommuterKnitter on Twitter and Facebook.	https://ssl-static.libsyn.com/p/assets/2/1/f/5/21f5af7bc0b2de81/New_Pink_Logo.jpg
1108	http://comopanatedigo.libsyn.com/rss	Como Pana Te Digo	Andres Vera y Daniela Anchundia	Talk show de humor donde Andrés y Daniela investigan y comentan las noticias más extrañas y los sucesos de su vida diaria junto a diferentes celebridades y amigos. Hecho en Ecuador para latinoamérica y el mundo.	https://ssl-static.libsyn.com/p/assets/2/a/d/a/2ada0e69f9a2c19e/portada-itunes-CPTD2_1400.jpg
1314	http://crayonsforpresident.podomatic.com/rss2.xml	Crayons for President	Nicholas Angelo		https://assets.podomatic.net/ts/8a/04/d8/nicholasangelobatten/1400x1400_9765024.jpg
1109	http://companyofburninghearts.podomatic.com/rss2.xml	Company of Burning Hearts (COBH)	Justin & Rachel Abraham	FREE Podcast - Justin Paul Abraham is the founder and co-director of COBH Ltd in the UK. He is a popular podcaster, author, missionary and motivational speaker, known for his joyful teachings on the happy gospel, engaging heaven, mystical (contemplative) prayer and KAINOS (new) creation realities. He lives in the UK with his four kids – Josh, Sam, Beth and Oliver with his inspirational wife Rachel Abraham.	https://assets.podomatic.net/ts/20/be/8a/companyofburninghearts/3000x3000_12598390.jpg
1110	http://compassionatecooks.libsyn.com/rss	Food for Thought: The Joys and Benefits of Living with Compassion and Purpose	Colleen Patrick-Goudreau, Author and Speaker	Emphasizing the fact that being vegan is a means rather than an end in itself, the Food for Thought podcast addresses all aspects of eating and living compassionately and healthfully. Each episode addresses commonly asked questions about being vegan, including those regarding animal protection, food, cooking, eating, and nutrition — and debunks the myths surrounding these issues. Hosted by bestselling author Colleen Patrick-Goudreau, Food for Thought has been changing lives for over a dozen years. Learn more at ColleenPatrickGoudreau.com.	https://ssl-static.libsyn.com/p/assets/7/8/a/2/78a2848614a083fc/podcastgraphicCPGfft_1400x1400.jpg
1112	http://completeliberty.libsyn.com/rss	Complete Liberty Podcast	Wes Bertrand	Have you had it with politics-as-usual? Are you curious about why the vague notion of "public interest" is constantly forwarded by those who want to control you and your property?\n\nDo you yearn for a day when you are respected as an individual? Do you want to learn about the implications of self-ownership? Do you desire to live in a brilliantly better future?\n\nA dangerous myth perpetuates our political plight in America - the belief that we are free. In fact, scores of unjust laws violate our individual rights daily. We are taxed, regulated, and forced to fund governmentally monopolized services, and if we attempt to defend ourselves from any of these infringements, we are fined, arrested, punished, or even destroyed. We are no longer subjects to the King, but are we veritable slaves to the State? Most of us are afraid to answer this question, because it's easier to conform and pretend that the myth of our freedom is true. But living in fear and being obedient aren't the essence of the American spirit - embracing liberty is. \n\nComplete Liberty Podcast explains not only the sundry ills of statism, but also why political freedom is so important - and how we, as Americans, can achieve it.\n\nVisit the website of the book at www.completeliberty.com.	https://ssl-static.libsyn.com/p/assets/1/7/4/5/174565182524b87f/newitunes1400.jpg
1113	http://completepic.adobetv.libsynpro.com/Nano	The Complete Picture with Julieanne Kost	Adobe TV	Join Julieanne Kost, Digital Imaging Evangelist at Adobe Systems. In each episode, you'll obtain valuable insights and in-depth information on a variety of topics covering both Photoshop and Lightroom.	http://static.libsyn.com/p/assets/a/2/2/b/a22b9485ec129258/JK_artwork.png
1114	http://completepic.adobetv.libsynpro.com/iphone	The Complete Picture with Julieanne Kost	Adobe TV	Join Julieanne Kost, Digital Imaging Evangelist at Adobe Systems. In each episode, you'll obtain valuable insights and in-depth information on a variety of topics covering both Photoshop and Lightroom.	http://static.libsyn.com/p/assets/a/2/2/b/a22b9485ec129258/JK_artwork.png
1115	http://completepic.adobetv.libsynpro.com/rss	The Complete Picture with Julieanne Kost	Adobe TV	Join Julieanne Kost, Digital Imaging Evangelist at Adobe Systems. In each episode, you'll obtain valuable insights and in-depth information on a variety of topics covering both Photoshop and Lightroom.	http://static.libsyn.com/p/assets/a/2/2/b/a22b9485ec129258/JK_artwork.png
1117	http://computertutorflorida.com/feed/podcast/	The Computer Tutor	pctutor@gmail.com (Scott Johnson)	The Computer Tutor podcast is a weekly show that offers all kinds of cool things that help you use your computer more easily and effectively.  You'll say, "Wow, that's cool - I never knew I could do that!"  Show notes for each episode are at http://ComputerTutorFlorida.com	http://computertutorflorida.com/wp-content/uploads/2012/08/The_Computer_Tutor.jpg
1118	http://computerweekly.podOmatic.com/rss2.xml	podcasts @ComputerWeekly	Podcasts @ComputerWeekly	ComputerWeekly.com brings you a weekly round-up of the latest IT news from the UK. Also available: interviews with leading IT experts on a range of business computing and information technology topics.\n\nhttp://wwww.computerweekly.com	https://assets.podomatic.net/ts/8d/fe/d4/computerweekly/pro/3000x3000_1236358.jpg
1119	http://computerwiz720.podbean.com/feed/	CC&B Podcast	CC&E Productions	A Group of young students put on their own podcast segments. Brandon Does Prank calls, Corbin does news report, Colby does Reviewing and Affiliate.	https://pbcdn1.podbean.com/imglogo/image-logo/14668/Photo9.jpg
1120	http://comtruise.com/kc/feed.xml	Komputer Cast	Com Truise	Vintage synth-funk for the modern nostalgic individual.	http://comtruise.com/kc/images/itunes-kc8.jpg
1121	http://concertblast.podomatic.com/rss2.xml	CONCERT BLAST!	CONCERT BLAST!	WELCOME TO CONCERT BLAST! A Weekly Podcast of 3 guys who grew up together (Mike Arnold, Brian Hasbrook, and Tom Thompson) in the Nashville, TN area. Concert Reviews, Interviews, and Music Discussions. JOIN US!	https://assets.podomatic.net/ts/66/21/35/concertblast/3000x3000_598926.jpg
1125	http://conductor-anonimo.podomatic.com/rss2.xml	Podcast FreeStylers	conductoranomino	Programa Transmitido de Lunes a Viernes\na las 21:00 hrs (Hora de Mexico) en vivo desde\nTampico Tamaulipas Mexico http://www.adngeneticamenteradio.com	https://assets.podomatic.net/ts/71/dd/79/vcrtxhal/3000x3000_3186286.jpg
1127	http://conferenceofthebirds.podbean.com/feed/	Conference of the Birds Podcast	Stephen Cope	Weekly podcast of music from Africa, Asia, the Americas, the Middle-East, and Europe with an emphasis on cross-cultural exploration and experimentation. Hosted by Stephen Cope.	https://pbcdn1.podbean.com/imglogo/image-logo/163134/StudioCope2.jpg
1128	http://conferences.optionsinsider.libsynpro.com/rss	Options Insider Special Events	The Options Insider Inc.	Your front-row seat for compelling panel audio and special event recordings from the world of options. In addition to free audio from leading options conferences, you will also have access to special recordings, roundtables and other exclusive Options Insider events. So if you missed a recent options conference, or if you simply cannot afford to attend the numerous events around the country, The Options Insider has you covered. Let our Options Insider Special Events program give you a front-row seat to the world of options.	http://static.libsyn.com/p/assets/3/f/7/1/3f71c52454d557ac/Special_Events_Radio_Cover_Art.jpg
1136	http://connvincemedia.podomatic.com/rss2.xml	ConnVince MEdia Podcast	Connie Rollins	This podcast discusses the different types of media including Photography, Videography, Audio Engineering, Film, Cinematography, Cameras, etc.  We interview specialists in these fields.	https://assets.podomatic.net/ts/94/ff/e7/orlphotog/3000x3000_5856301.jpg
1577	http://data.kgbr.co.kr/podcast/kgbr.xml	한국복음서원	한국복음서원	한국복음서원에서 제공하는 은혜의 말씀	https://data.kgbr.co.kr/podcast/logo.jpg
1144	http://conspiracyworldwide.podOmatic.com/rss2.xml	Conspiracy Worldwide Hip Hop Radio	Conspiracy Worldwide Radio	Tweets from @conspiracyradio/montana-menace\n!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0],p=/^http:/.test(d.location)?'http':'https';if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src=p+"://platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nvar sc_project=5281597; \nvar sc_invisible=1; \nvar sc_partition=59; \nvar sc_click_stat=1; \nvar sc_security="e5dca755"; \n\n\n\n\nFeedjit Live Blog Stats\n\n\n\n\nblog counter\n\n\n\nwidgeo.net\n\n\n\n\n\n\n\n\nw3counter(31499);\n\n\n\n\n\n\n\n\n\n  \n \n \nGet the NeoCounter widget and many other great free and Premium widgets at NeoWORX!	https://assets.podomatic.net/ts/fe/f7/b3/conspiracyworldwide/3000x3000_1425025.jpg
1145	http://constitution.podOmatic.com/rss2.xml	Il podcast del cittadino	i s	Podcast multilingue di educazione alla cittadinanza	https://assets.podomatic.net/ts/44/8b/62/constitution/1400x1400_1873527.jpg
1149	http://content.bitsontherun.com/feeds/2ALtu3Xw.rss	HSBC.WV	Huntington School of Beauty Culture, Huntington, WV		http://content.bitsontherun.com/v2/media/2ALtu3Xw/poster.jpg
1175	http://content.bitsontherun.com/feeds/vLM8lxuj.rss	eltiempotv.com	Atmosférica Productos Meteorológicos S.L.	Atmosférica es una productora que ofrece productos meteorológicos y climatológicos para diferentes medios y plataformas. Disponemos de un equipo de meteorólogos con una larga trayectoria profesional. Nuestra larga experiencia nos permite ser muy conscientes de la transcendencia de la meteorología en las diferentes actividades de nuestra sociedad y de la magnitud de los fenómenos meteorológicos.	http://content.bitsontherun.com/v2/media/vLM8lxuj/poster.jpg
1178	http://content.chattanoogastate.edu/bteem/TYCAT/TYCASE10.xml	Highlights from TYCA-SE 2010, Chattanooga, TN	William Teem	Some session from Chattanooga	\N
1179	http://content.chattanoogastate.edu/bteem/lectures/al10flec.xml	Prof. Teem's 2010 fall lectures for American Literature I	William Teem	Professor Teem's lectures from class to assist those who miss class and to help all prepare for exams	http://content.chattanoogastate.edu/bteem/images/TeemUVA.jpg
1180	http://content.chattanoogastate.edu/bteem/lectures/al10slec.xml	Prof. Teem's 2010 spring lectures for American Literature I	William Teem	Professor Teem's lectures from class to assist those who miss class and to help all prepare for exams	http://content.chattanoogastate.edu/bteem/images/TeemUVA.jpg
1181	http://content.chattanoogastate.edu/bteem/lectures/al11slec.xml	Prof. Teem's 2011 spring lectures for American Literature II	William Teem	Professor Teem's lectures from class to assist those who miss class and to help all prepare for exams	http://content.chattanoogastate.edu/bteem/images/TeemUVA.jpg
1182	http://content.chattanoogastate.edu/bteem/lectures/al11ulec.xml	Prof. Teem's 2011 summer lectures for American Literature I	William Teem	Professor Teem's lectures from class to assist those who miss class and to help all prepare for exams	http://content.chattanoogastate.edu/bteem/images/TeemUVA.jpg
1183	http://content.chattanoogastate.edu/bteem/rhelps/al10f.xml	Prof. Teem's '10 fall reading helps for American Literature I	William Teem	Get a better understanding of the readings for American Literature I at Chattanooga State and review for quizzes and exams	http://content.chattanoogastate.edu/bteem/images/TeemUVA.jpg
1184	http://content.chattanoogastate.edu/bteem/rhelps/al10s.xml	Prof. Teem's '10 spring reading helps for American Literature I	William Teem	Get a better understanding of the readings for American Literature I at Chattanooga State and review for quizzes and exams	http://content.chattanoogastate.edu/bteem/images/TeemUVA.jpg
1185	http://content.chattanoogastate.edu/bteem/rhelps/al11s.xml	Prof. Teem's '11 spring reading helps for American Literature II	William Teem	Get a better understanding of the readings for American Literature II at Chattanooga State and review for quizzes and exams	http://content.chattanoogastate.edu/bteem/images/TeemUVA.jpg
1186	http://content.chattanoogastate.edu/bteem/rhelps/al11u.xml	Prof. Teem's '11 summer reading helps for American Literature I	William Teem	Get a better understanding of the readings for American Literature I at Chattanooga State and review for quizzes and exams	http://content.chattanoogastate.edu/bteem/images/TeemUVA.jpg
1187	http://content.everydayhealth.com/jillianmichaels/podcasts/jm-podcast-feed.xsl	The Jillian Michaels Show	Customer Support	Jillian Michaels, America's Health and Wellness guru, brings you the Jillian Michaels Show.  An entertaining, inspirational, informative show that gives you tools to find health and happiness in all areas of your life.	http://images.agoramedia.com/jillianmichaels/publicsite/jm__podcast_icon.jpg
1191	http://content.zdf.de/podcast/zdf_hjo/hjo.xml	Video-Podcast des ZDF heute-journals	ZDFheute	Das heute-journal des ZDF	http://www.heute.de/heute_de.jpg
1192	http://contentradio.podomatic.com/rss2.xml	Content Radio	Totalspiel Branded Content	De laatste cases, ontwikkelingen en ideeën over content marketing op je mobiel	https://assets.podomatic.net/ts/ad/a0/12/45585/3000x3000_8131049.jpg
1193	http://contestandotupregunta.podbean.com/feed/	Contestando Tu Pregunta	Ramon Romero	El Lic Ramon Romero presenta interesantes temas religiosos para este tiempo.	https://pbcdn1.podbean.com/imglogo/image-logo/86487/contestandotupregunta2.jpg
1194	http://continuecast.podomatic.com/rss2.xml	ContinueCast	Continue?	Every month Nick, Josh, Paul and Luke play a new classic retro video game. Two episodes a month - one of first impressions, the second is our final verdict - Continue? or Game Over. \n\n\nSubscribe! \nhttp://www.YouTube.com/ContinueShow \nLike us on Facebook! \nhttp://www.facebook.com/ContinueShow \nFollow us on Twitter! \nhttp://www.twitter.com/ContinueShow \n\nSuggest games for us to play and give play along with us! We'll read your emails on the show!\nContinuePodcast@gmail.com	https://assets.podomatic.net/ts/54/a0/4d/paulritchey/3000x3000_8117521.jpg
1196	http://contraflowparty.podOmatic.com/rss2.xml	CONTRAFLOW PODCAST	The Cosmic Jam	Good Music...	https://assets.podomatic.net/ts/8e/bd/53/contraflowparty/3000x3000_765236.jpg
1200	http://conversationswithapollo.podomatic.com/rss2.xml	Conversations with Apollo	Conversations with Apollo		https://assets.podomatic.net/ts/c7/f2/b1/apollotalks21694/3000x3000_5402879.jpg
1202	http://converttoraid.libsyn.com/rss	Convert to Raid: The podcast for raiders in the World of Warcraft!	Pat Krane	Convert to Raid is the podcast for raiders in World of Warcraft!  Our panel of avid players will talk about the latest buzz in the game and how it affects the end game.	https://ssl-static.libsyn.com/p/assets/d/6/c/b/d6cb3f69557ac922/CTR_Dragon_Logo_2019.png
1204	http://cookerhat.podomatic.com/rss2.xml	AND NOW THAT WE HAVE YOUR ATTENTION...	AND NOW THAT WE HAVE YOUR ATTENTION...	Intellectual crap by a bunch of bored guys, what's not to like!	https://assets.podomatic.net/ts/88/14/fe/cookerhat/1400x1400_2891244.jpg
1205	http://cookevilleag.libsyn.com/rss	Live Life Church	Cookeville Life Church	Messages from Cookeville Life Church	https://ssl-static.libsyn.com/p/assets/f/7/1/2/f712fdd3b2dfcf23/LC1400-01.jpg
1209	http://coolblindtech.com/podcast?format=rss	All Cool Blind Tech Shows	nelson@coolblindtech.com (CBT)	Cool Blind Tech strives  for universal design of products, environments, programmes and services to be usable by all people, to the greatest extent possible, without the need for adaptation or specialized design, not excluding assistive devices for particular groups of individuals with disabilities where this is needed.<br />\n<br />\nThe Cool Blind Tech Team endeavours in   maximizing the independence, productivity and participation of the blind and low vision community, to empower the blindness community through the acquisition and<br />\nenhancement of skills in using  adaptive technologies.	https://www.CoolBlindTech.com/wp-content/uploads/powerpress/CBT_Logo_(1400x1400).JPG
1210	http://coolclass.podOmatic.com/rss2.xml	Kidcasts.org	Kidcasts.org	Kidcasts.org, sharing kids' voices from around the world.	https://assets.podomatic.net/ts/40/2f/62/coolclass/3000x3000_13037532.jpg
1212	http://coollcast.podOmatic.com/rss2.xml	Coollcast	Lu K		https://assets.podomatic.net/ts/d0/0c/63/coollcast/3000x3000_2525240.jpg
1214	http://coopertalk.podbean.com/feed/	CooperTalk	Steve Cooper	Straight out of Philly! Entertainer Steve Cooper is “Only as hip a his guests”. He hosts Comedians, Actors, Writers and Musicians and spends an hour with them for some organic chat about the biz!	https://pbcdn1.podbean.com/imglogo/image-logo/330970/Coop_thumbnail.jpg
1217	http://copperworkersample.podomatic.com/rss2.xml	Maria N's Podcast	Maria N		https://copperworkersample.podomatic.com/images/default/podcast-4-3000.png
1218	http://copticscotland.podomatic.com/rss2.xml	Coptic Scotland Podcast	St Mark's Coptic Orthodox Church Scotland	If you've never heard Fr Mark speak, here is your chance!	https://assets.podomatic.net/ts/7e/18/73/podcast29050/3000x3000_5921141.jpg
1219	http://copyfonico.podomatic.com/rss2.xml	copyfonico's Podcast	copyfonico		https://copyfonico.podomatic.com/images/default/podcast-3-3000.png
1220	http://coracle.jellycast.com/podcast/feed/543	The tanker market from ShippingPodcasts.com	coracle	Weekly market reports on the worlds tanker markets. \nThis podcasts gives you the latest in the VLCC, Suezmax, Aframax and Clean Petroleum Products tanker trades.	https://coracle.jellycast.com/files/tankers.png
1222	http://cordellbank.noaa.gov/casts/rss.xml	Ocean Currents Radio Program	Jennifer Stock (jennifer.stock@noaa.gov)	Ocean  Currents is hosted by Cordell Bank National Marine Sanctuary on KWMR, community radio for West Marin in Northern California. The show hosts ocean experts about research, management issues, natural history, and stewardship associated with marine environment, especially in our National Marine Sanctuaries.	https://cordellbank.noaa.gov/casts/oceancurrentslogo_itunes.jpg
1227	http://cornerstone-pc.com/podcast.php?pageID=21	Cornerstone PC	Cornerstone Presbyterian Church	Sermons from Cornerstone Presbyterian Church (PCA) in Lansdale, PA. Cornerstone exists to glorify God by making gospel-centered disciples who will bring the hope and renewal of Jesus Christ to greater Philadelphia and the world.	https://clovermedia.s3-us-west-2.amazonaws.com/store/4a/4aba5d9b-cfe2-40d0-befc-0c75ac95bfac/thumbnails/mobile/7e782cbd-53bd-47b3-a9f9-36373a90a394.jpg
1228	http://cornerstonechapel.net/podcasts/collections/C02012013/C02012013-Audio.xml	Cornerstone Chapel - The Minor Prophets (Audio)	Cornerstone Chapel	The last twelve books of the Old Testament are known as "the Minor Prophets."  They are "minor" not because they are less important than the other Old Testament prophets, but because their messages are generally shorter and more succinct.  The Minor Prophets are filled with exhortations from men, moved by God, who spoke out against the social and cultural sins of their day.  They called people to repentance.  They challenged people to turn to God.  Sometimes their hearers heeded the message, and sometimes they did not.  And even though their voices have been silent for some 2,500 years now, their messages are timeless - God wants us to repent of sin and turn to Him!	http://cornerstonechapel.net/podcasts/collections/C02012013/images/C02012013-Audio.jpg
1229	http://cornerstonechapel.net/podcasts/collections/C11102010/C11102010-Audio.xml	Cornerstone Chapel - In Depth Study Of The Book Of Revelation (Audio)	Cornerstone Chapel	Jesus is coming again!  There are three times as many prophecies in the Bible concerning the second coming of Jesus than there are prophecies concerning His first coming.  In the book of Revelation, God pulls back the curtain and allows us to have a glimpse of things that are to come.  He shows us the Judgments, the Antichrist, the False Prophet, the rise and fall of the one-world economic and political system, and the Battle of Armageddon, to name a few scenes.  But He also shows us how He rescues the righteous before the Tribulation, how He saves those who repent during the Tribulation, and how He even dispatches an angel to proclaim the gospel around the world so that as many people as possible might accept the good news of Jesus Christ.  The closing chapters of Revelation are about the Second Coming of Jesus Christ and the amazing future that He promises for all who belong to Him!	http://cornerstonechapel.net/podcasts/collections/C11102010/images/C11102010-Audio.jpg
1230	http://cornerstonechapel.net/podcasts/collections/C12172012/C12172012-Audio.xml	Cornerstone Chapel - The Ten Commandments (Audio)	Cornerstone Chapel	The Ten Commandments have been, without a doubt, the most influential document upon human culture, in general, and upon American culture in particular - framing both the social and legal foundations of our American Society.  In Colossians 2:16-17 and Mark 7:18-23, we find that the ceremonial and dietary aspects of the Old Testament law are no longer binding; however, the moral code is still intact.  The Ten Commandments are the summary of God's moral code and are intended to shape the way we live - our actions, speech, and attitudes.  There are no exceptions to the moral code because it is an absolute, not a relative code.  In other words, it doesn't change because of changing times or cultural views; it expresses God's moral standard for human behavior toward God and toward others.	http://cornerstonechapel.net/podcasts/collections/C12172012/images/C12172012-Audio.jpg
1231	http://cornerstonechapel.net/podcasts/csAudioPodcast-HighSchool.xml	Cornerstone Chapel - High School Youth Ministry Podcast	Cornerstone Chapel	At Cornerstone Chapel, it is our desire that you see the love of Jesus Christ reflected through the systematic, verse by verse teaching of the Bible and through heart-felt, contemporary worship lifted up to God.	https://cornerstonechapel.net/podcasts/images/csAudioPodcast-HighSchool.jpg
1232	http://cornerstonechapel.net/podcasts/csAudioPodcast-Men.xml	Cornerstone Chapel - Men's Ministry Podcast	Cornerstone Chapel	At Cornerstone Chapel, it is our desire that you see the love of Jesus Christ reflected through the systematic, verse by verse teaching of the Bible and through heart-felt, contemporary worship lifted up to God.	https://cornerstonechapel.net/podcasts/images/csAudioPodcast-Men.jpg
1315	http://crazy-babble.podspot.de/rss	Crazy-Babble	Julia, Agnes, Marlen und Ina	Wir (J.A.M.I. d.h. vier verrückte fünfzehnjährige Mädchen namens  Julia, Agnes, Marlen und Ina) machen einen Podcast...\r\n\r\nSkype+MSN: crazy-babble@hotmail.de\r\nICQ: 353-488-135	\N
1233	http://cornerstonechapel.net/podcasts/csAudioPodcast-MiddleSchool.xml	Cornerstone Chapel - Middle School Youth Ministry Podcast	Cornerstone Chapel	At Cornerstone Chapel, it is our desire that you see the love of Jesus Christ reflected through the systematic, verse by verse teaching of the Bible and through heart-felt, contemporary worship lifted up to God.	https://cornerstonechapel.net/podcasts/images/csAudioPodcast-MiddleSchool.jpg
1235	http://cornerstonetucson.com/podcast.xml	Cornerstone Bible Church - Tucson, AZ.	Cornerstone Bible Church Tucson	Pastor Al Addleman is currently teaching studies out of the Book of Ephesians. Al will be teaching the Book of Epesians verse by verse and line by line. The objective is to see what God's Word says and how we apply it to our lives today. Studies for other Books of the Bible are also available.	http://www.cornerstone.com/images/cornerlogo.jpg
1239	http://cornishavclub.podOmatic.com/rss2.xml	The Cornish A.V. Club Podcorn	AV_CLUB	Music and video games and movies and books and comics and the computer internet.	https://assets.podomatic.net/ts/33/a2/0e/cornishavclub/3000x3000_2294309.jpg
1240	http://coronacay.com/coronaverse/rss	Comments on: Coronaverse	\N	Second Life Community Website	\N
1247	http://corruptradio.podomatic.com/rss2.xml	Unknown Radio UK podcasts	Unknown Radio UK	The Unknown Radio UK Podomatic page gives you the most up to date shows and guest mixes from the Unknown Radio crew, downloadable straight to your iPhone, iPod or MP3 device. http://www.unknownradio.uk	https://assets.podomatic.net/ts/53/8d/23/info29516/3000x3000_13224729.jpeg
1251	http://corvennetworks.jellycast.com/podcast/feed/2	Corven Group	corvennetworks	Corven Networks brings together leaders from high-performing companies to challenge conventional thinking, share real experiences and develop practical solutions. Through everyone's ongoing commitment to sharing lessons learned, members benefit from the extensive knowledge-pool of leading organisations, enabling them to deliver exceptional results in their own firms.\n \nWe focus on four different areas of strategic importance - Corporate Venturing, Innovation, Leadership and Operational Excellence.	https://corvennetworks.jellycast.com/files/iTunes%20podcast%20image.jpg
1252	http://corvidae.co.uk/saki/clovis.xml	The Chronicles of Clovis	Richard Crowest	‘Never speak ill of society. Society is perfectly capable of doing that for itself...’\n\nA series of professionally produced readings of the Chronicles of Clovis. View the world of Edwardian society through the jaundiced eye of Clovis Sangrail, Saki's deliciously louche anti-hero.	http://corvidae.co.uk/saki/beasts.jpg
1253	http://cosmiclionradio.libsyn.com/rss	Cosmic Lion Radio	Eli Schwab	Step into the mind of Gonzo Musicologist Eli Schwab as he takes you to the outer reaches of Comic Books, Music, Films, Art, and beyond	https://ssl-static.libsyn.com/p/assets/d/3/2/f/d32f4606e1a0cc86/CLRCover.jpg
1254	http://cosmicradio.tv/feed/8bitlife/	My So Called 8bit Life	podcasts@cosmicradio.tv (Coscmic Radio TV LLC)	Random topics. Random guests. Always geeky. Join host Roberto Villegas in this conversational interview podcast with geeks of all kinds.	http://29aaf80a2dc8406c9b57-4154b876a024904b88ddcfca3ad2d9c2.r46.cf2.rackcdn.com/itunesimages/8bitlife.png
1255	http://cosmicvibes.podomatic.com/rss2.xml	Lilly Natures Blessings' Podcast	Lilly Natures Blessings	Profound insight, Messages from the Spirit World, SPECIAL Spiritual Techniques received from Spirit, meditations, inspiration, motivation and more ~ Aloha	https://assets.podomatic.net/ts/a3/16/09/count90210/pro/3000x3000_5817300.jpg
1256	http://cosmochurch.org.za/sermons/feed.xml	Cosmo City Church	Cosmo City Church	Messages from Cosmo City Church services	http://cosmochurch.org.za/sermons/images/itunes_image.jpg
1257	http://cosmopolyphonic.podOmatic.com/rss2.xml	Alice Clemons' Podcast	Alice Clemons		https://cosmopolyphonic.podomatic.com/images/default/podcast-3-3000.png
1258	http://costep.hucc.hokudai.ac.jp/podcasting.xml	かがく探検隊コーステップ （科学バラエティ番組：北海道大学CoSTEP制作）	科学技術コミュニケーター養成ユニット	科学技術コミュニケーター養成ユニット（CoSTEP)が制作した科学バラエティ・ラジオ番組です。	http://costep.hucc.hokudai.ac.jp/costep/modules/bulletin/images/podcast.jpg
1265	http://couchcoop.podbean.com/feed/	Couch Co-Op	couchcoop	Welcome to Couch Co-Op! Your hosts Andy, Dylan, and Vinny revisit and breakdown classic games from our youth.	https://djrpnl90t7dii.cloudfront.net/podbean-logo/podbean_58.jpg
1271	http://countdown.podOmatic.com/rss2.xml	The Cool Jazz Countdown	TenShare-TVM Productions	A weekly survey of the top jazz albums of the week, hosted by Marcellus "The Bassman" Shepard and Kyle LaRue	https://countdown.podomatic.com/images/default/T-3000.png
1273	http://courses.ucsd.edu/rgrush/podcasts/logic-audio/Logic-Audio.xml	Logic (Audio w/ .pdfs)	Rick Grush (rick@mind.ucsd.edu)	Audio of lectures, and .pdfs of powerpoint slides, for Philosophy 10, Introduciton to Logic, UC San Diego.	http://courses.ucsd.edu/rgrush/podcasts/logic-audio/Logic-Audio.jpg
1274	http://courtesyflush.podOmatic.com/rss2.xml	The Courtesy Flush	The Courtesy Flush		https://assets.podomatic.net/ts/49/be/21/courtesyflush/pro/3000x3000_2643623.jpg
1275	http://courtreportingredlion.podOmatic.com/rss2.xml	Fall 2016	John DeCaro	Sometimes it seems like nothing is happening when you practice the same take over and over so slowly that it seems the world has stopped.  That is not the case.  Magnificent things are happening in your nervous system behind the scenes.  Read the quote below by an eminent scholar.\n\n"During the early stages of learning, muscle combinations, tensions and releases are under conscious control and continue to change and re-configure themselves according to what the mind has ordered.  In other words, a perceptual mandate creates a mental template.  The muscles, through trial and error, attempt to achieve what the mind has conceived, or come as close to the template as possible.  As the mind receives knowledge of results, subsequent movements are changed and refined until the desired degree of accuracy is achieved."\n\nJ. Dickinson.  "Some Perspectives on Motor Learning Theory."\n\n-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -\n\nWhen you use the podcast for practice, please leave your footprint by clicking the "comment" button and keying your name.  I can roll number of visits into the homework grade.  \n\n-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -   \n\nWHAT IS AN ANALYTICAL CRITIQUE?\n\nAnalysis\nAna in Greek means “up” or “through.”\nLysis in Greek means “to break up” or “loosen.”\n\nIn an analysis, you break things apart and look at the individual parts in their individuality.\n\nCritical Analysis in General Terms:\nA critical analysis in general terms often means negative carping.   For example, your spouse says, “You are wrong, wrong, wrong.”     This is not our sense of the word "criticism," the analytical sense.  \nIn an analytical critique, we endeavor to know something's limits.   We try to find out what something can do inside of its limits.  Then we ask in what places do those limits prevent something from doing something else. \n\nIn Steno Terms Ask:\nQ.     What can your writing now do inside of its limits?  In other words, what parts of writing steno give you little or no problems?  \nA.      \nQ.     What prevents your writing from doing something else that it should be doing?  In other words, what parts of writing steno are consistently giving you problems?\nA.      \n\nConsider stepping back from your writing and trying to recognize it for what it is within its own borders.  The counterproductive alternative is to live directly inside of it and, consequently, invest excessive emotion in it.  The result is that you take your current skill level for granted and accept it as being you; that is to say, you are in danger of letting your limitations define you.  Then you might freeze up.\n\nYour weaknesses are not you.  They are just regular human limitations that can often be remediated by training and maturation.  Stepping back and creating a little space between your skill level and your emotions will allow you to set small goals that should foster overall improvement.  \n\nIn the end, your goal is not writing perfection.  That is not possible.  Similarly, your goal is not to be a better writer than anyone or everyone else.  Don’t worry about anyone else.  Sure, compete with them, but use them only as a gauge of your skill level.\nYour main competition can now be against the program itself, which exits primarily to rub against the grain of inactivity, and through channeled activity, prepare you to be an entry-level machine writer.   Your only competition is you and the challenges of the program, and your goal is to mature and improve until you reach a professional skill level.  At that point, you have employable machine shorthand skill.  That is true graduation.  It facilitates entry into the profession.   \n\n-  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -\n\nPractice Tips from the Pros\n\n1) Write from hard copy but don’t just “write through” the hard copy.  When you make a mistake, go back a few words and write through the trouble spot at half the speed. Do(continued)	https://assets.podomatic.net/ts/55/ab/d9/courtreportingredlion/3000x3000_2546883.jpg
1276	http://courtsidebasketball.podomatic.com/rss2.xml	The Courtside Podcast	Courtside	Welcome to The COURTSIDE Podcast, join your hosts Hank McCoy and Vince Germano as they bring you all the laugh out loud moments in each episode. \n\nIt's Australia's zaniest NBA show! \n\nwww.CRTSDE.com	https://assets.podomatic.net/ts/e8/a7/5a/courtsidebasketball/3000x3000_10021126.jpg
1277	http://couv.com/images/galleries/localRSS.xml	Local Community, Vancouver WA	COUV.COM	Stories from our local community	\N
1280	http://covenantumc.sitewrench.com/swx/pp/media_archives/73511/channel/1149.xml	Sermons Podcast	Webmaster	Sunday Sermons	http://covenantumc.sitewrench.com/assets/1380/
1281	http://coventryuniversity.podbean.com/feed/	The Mada Java University's Podcast	coventryuniversity	Self improvement by mada java.	https://pbcdn1.podbean.com/imglogo/image-logo/6462666/pic10.jpg
1286	http://cowoi.podspot.de/rss	Cowoi.de.vu	Alex / Crush @ Cowoi.de.vu	Alles mögliche zum Thema Kochen und Webdesign	\N
1322	http://crclondonmedia.podomatic.com/rss2.xml	CRC London - Pastor Thabo Marais	Pastor Thabo Marais	Pastor Thabo Marais was appointed as Senior Pastor of CRC London in 2008. His mandate is to build one church in many locations throughout the UK and Europe and together with his wife, Karen, his ultimate passion is to win souls for Jesus through a vibrant and dynamic church.	https://assets.podomatic.net/ts/b4/d2/9c/media32/3000x3000_11199518.jpg
1332	http://createdlistening.com/category/podcast/feed/	Podcast – Created Listening	createdlistening@gmail.com (Created Listening)	Creavit Audiendo: Technological Advances in Podcrastination. A podcast for nerds. We talk about TV shows, movies, books, technology, and more.	http://createdlistening.com/wp-content/uploads/2013/01/logo1.png
1289	http://coyotecast.podOmatic.com/rss2.xml	coyotecast's Podcast	GWCS CoyoteCast	Founded in the summer of 1999, the GW Community School embraces as its mission the development and implementation of a holistic educational program which will develop and optimize the giftedness and intelligence of each student in an in-depth, enriched, and technically advanced college preparatory environment that emphasizes authentic application of knowledge, not merely assimilation of information.\n                \n                Students will experience academic success and the development of social awareness and responsibility in an atmosphere where all are treated with respect and courtesy. \n                \n                The GW Community School recognizes the unique contribution of parents, students and community members striving for unity of purpose.	https://assets.podomatic.net/ts/c3/7d/2a/coyotecast/1400x1400_1181777.jpg
1290	http://coyotes.nhl.com/podcasts/coyotes_radio_interviews.xml	Arizona Coyotes Radio Interviews	Arizona Coyotes Podcast	Arizona Coyotes Players and Coaches Media Appearances	http://coyotes.nhl.com/ext/podcasts/coyotescast_300.jpg
1291	http://coyotes.nhl.com/podcasts/postgame.xml	Arizona Coyotes Post-Game Press Conference	Arizona Coyotes Podcast	Post Game Press Conference with Dave Tippett	http://coyotes.nhl.com/ext/podcasts/coyotescast_300.jpg
1292	http://cpcast.podOmatic.com/rss2.xml	Club Penguin Podcast	Emilio & Pete	This is a podcast where we guide you through the snowy world that is Club Penguin with tips tricks reviews and more! We always have up to date news and what you want to hear about club penguin. And there are plenty on contest going on.Our site is clubpenguinpodcast.com go on and check it out.	https://assets.podomatic.net/ts/01/a2/03/cpcast/3000x3000_1023194.jpg
1293	http://cpcheatsandglitches.podomatic.com/rss2.xml	Club Penguin Cheats And Glitches Podcast	Club Penguin Cheats And Glitches Podcast	This Podcast Brings To You All You Need To Know About Club Penguin With topgear01!	https://assets.podomatic.net/ts/d7/cc/cf/podcast72803/1400x1400_3318100.jpg
1294	http://cpcheatspodcast.podomatic.com/rss2.xml	The CP Cheats Podcast Team's Podcast	The CP Cheats Podcast Team	This is a club penguin podcast. If you like club penguin you will love this podcast. Our Website is:\ncpcheatspod.webs.com\n. Our Youtube is:\nhttp://www.youtube.com/user/CPCheatspodcast?feature=mhum	https://assets.podomatic.net/ts/aa/46/d6/cpcheats10461/1400x1400_3834673.png
1295	http://cpcvallejo.podbean.com/feed/	Community Presbyterian Ch. Vallejo, CA	Community Presbyterian Church	Welcome to Community Presbyterian Church (CPC) sermon podcast.  We hope this weekly podcast will encourage and challenge you.  If you live in the area, we would for you to visit us.  For direction and more information about CPC, visit us at www.cpcvallejo.org.	https://pbcdn1.podbean.com/imglogo/image-logo/132417/CPCLOGO3.jpg
1296	http://cpidebarra.podomatic.com/rss2.xml	CPIDE OAB/RJ Barra da Tijuca	CPIDE OAB/RJ Barra da Tijuca	Comissão de Propriedade Intelectual e Direito do Entretenimento da OAB/RJ - Subseção Barra da Tijuca	https://assets.podomatic.net/ts/a9/72/fd/kuster75184/3000x3000_6435282.jpg
1297	http://cpnea.libsyn.com/rss	LifeSpring Bible Church	LifeSpring Bible Church	LifeSpring Bible Church is a Christian non-denominational church in Anchorage, Alaska. We don't care how messy your life is, we are a mess too! We are a family of broken people for broken people, discovering healing together. \nVisit us at https://www.lifespringak.com\nLike us on facebook https://www.facebook.com/lifespringak	https://d3t3ozftmdmh3i.cloudfront.net/staging/podcast_uploaded_nologo/1986455/3987a78d6cb518cb.jpeg
1298	http://cppodden.podomatic.com/rss2.xml	Jonas Helgesson Proudly Presents - Cp-podden	Cp-Podden	Podcast av och med Jonas Helgesson och Robin Lindholm. Egentligen tänkt som en förlängning av Jonas föreläsningar men det kan slinka igenom lite nonsens också...	https://assets.podomatic.net/ts/cd/a2/dc/cppodden/3000x3000_6403482.jpg
1299	http://cprchristianpaulradio.podomatic.com/rss2.xml	Reflections	Christiano	Always progressing in some shape or form staying true to the scene. Stay tuned for more deep/tech mixes form yours truly. Thanks For The Love & Support. Christiano	https://assets.podomatic.net/ts/30/69/c1/podcast7248669317/3000x3000-1063x1063+0+7_10483690.jpg
1301	http://cqueer.podomatic.com/rss2.xml	C-queer / queer radio	C-Queer (queer radio)	Broadcast sobre el cuerpo, sus políticas y economías desde la mirada queer.\n\nC-Queer es una producción independiente con el apoyo de la Universidad del Claustro de Sor Juana, Cd. de México.	https://assets.podomatic.net/ts/3c/73/12/cqueer/3000x3000_2372055.jpg
1304	http://crabfeast.fakemustache.libsynpro.com/rss	The HoneyDew with Ryan Sickler	Ryan Sickler	The HoneyDew is a storytelling podcast hosted by comedian, Ryan Sickler. Inspired by Ryan's adverse upbringing, the show focuses on highlighting and laughing at the lowlights of life.	http://static.libsyn.com/p/assets/9/a/0/1/9a01a284fd721c8f/HD_iTunes_2500x.jpg
1305	http://craftbeertemple.com/videos/BeerTempleRSS1.xml	The Beer Temple Podcast (HD)	The Beer Temple	Certified Cicerone Christopher Quinn discusses beer in a fun and informal way.	http://craftbeertemple.com/videos/BTLogos_copy.jpg
1307	http://craftcast.libsyn.com/rss	CRAFTCAST	Alison lee	On Craftcast.com, host Alison Lee takes you through the world of Crafting, from interviews, product reviews, and do it yourself tutorials. Craftcast.com is the only podcast where you can listen, learn, and create!	https://ssl-static.libsyn.com/p/assets/0/4/8/b/048ba01a3999ef3b/logo_square.png
1308	http://craftlit.libsyn.com/rss	CraftLit - Serialized Classic Literature for Busy Book Lovers	Heather Ordover	CraftLit is—>Annotated Audiobooks for Busy People \n\nLove the classics (or wish you did) \n\n*** No time to pick up a book? Not any more! *** This weekly annotated audiobook podcast presents curated classic literature in a serialized format. The host—Heather Ordover—"teaches to the joke" by filling in any relevant tidbits before listening to the next chapter of the book.   \n\n*** Callers regularly send in voicemail comments for play on the air to keep the "book club" vibe going. ***    \n\nThe podcast has been in continuous weekly production since 2006 - our next book, "Anne of Green Gables" by Lucy Maud Montgomery, begins in January 2018. \n\n* * As seen in What's Hot on iTunes * * \nAs heard on NPR's Weekend Edition Sunday | FiberHooligans | Podcast 411 | Marly Bird's Yarn Thing Podcast | Math-4-Knitters | Eddie's Room | Libsyn's Podcasting Luminaries | Chilling Tales for Dark Nights | WEBS podcast\n\n--Classic Audiobooks: because loving great books in a busy world is tough--	https://ssl-static.libsyn.com/p/assets/a/b/5/b/ab5bf54ee4037bcc/craftlit_logo_1400.jpg
1311	http://craigandsam.com/Podcasts/podfeed.xml	Craig and Sam in the Morning	Craig and Sam	A lighthearted look at today's hot topics and pop culture mania as heard on Craig and Sam's morning show.	http://craigandsam.com/Images/CRAIG_AND_SAM_LOGO.jpg
1312	http://craigharlock.podomatic.com/rss2.xml	Electronically Organised Noise Show	Craig Harlock	Predominantly deep hypnotic techno with some ambient, drone etc sometimes thrown.	https://assets.podomatic.net/ts/e6/07/29/craigharlock/3000x3000_10720965.jpg
1313	http://craignybo.com/category/scarystorieswithcraignybo/feed/	Craig Nybo: Author/Musician	\N	Craig Nybo's World	\N
1323	http://cre8media.net/podcastfeeds/ASI.xml	Autosport International Show 2015 - NEC, Birmingham from the 8th to 11th January, 2015.	Matthew Jones	Covering over 1 million ft², Autosport International is the World’s Greatest four wheel indoor extravaganza!  Featuring every level of Motor Racing - from Karting up to Formula 1- and with exhibitors ranging from specialist race suppliers to major manufacturers showcasing their road and race cars; the show truly brings together the world of motorsport under one roof.	http://cre8media.net/podcastfeeds/asi2015.jpg
1324	http://cre8media.net/podcastfeeds/barc.xml	The British Automobile Racing Club Podcasts	Matt Jones	2020 News and Interviews from the British Automobile Racing Club / BARC First formed in 1912 as The Cyclecar Club, today the British Automobile Racing Club organises races at almost every venue in Britain, including meetings at Anglesey, Brands Hatch, Cadwell Park, Castle Combe, Croft, Donington Park, Knockhill, Lydden Hill, Oulton Park, Pembrey, Rockingham, Silverstone, Snetterton, and of course the BARC’s home circuit, Thruxton.	http://cre8media.net/podcastfeeds/BARCSocialmediaMAIN.jpg
1325	http://cre8media.net/podcastfeeds/bdwinterchampionships.xml	NAF Five Star Winter Dressage Championships 2019, 3 - 7 April	Matt Jones	The NAF Five Star brand joins us in celebrating all that is great about British dressage at this year's Winter Dressage Championships 3 - 7 April 2019. Talented amateurs and Britain's best compete side by side over five days of intense competition.\n\nHeld at one of the UK's top equestrian venues, Hartpury Arena, the championships offers competitors the chance to go head to head for 39 titles from Preliminary through to Intermediate I, and plays host to the ever popular Petplan Equine Area Festival Championships.	http://cre8media.net/podcastfeeds/itunes2018.jpg
1326	http://cre8media.net/podcastfeeds/brdcss.xml	BRDC SuperStars 2018 - Audio Podcasts	Matthew Jones	BRDC SuperStars is well established as a programme which any serious young British driver aspires to be part of. As the scheme only selects the very brightest prospects, competition for places is tough and keenly fought.\n\nThe SuperStars are supported with training programmes which the on-track results of the last two years suggest, do help give those taking part a competitive edge. SuperStars compete across the different disciplines from single seaters to prototypes, touring cars to GTs. Indeed, it is an important part of the scheme’s ethos to ensure that those who benefit from the support go on to be successful across all disciplines of motor sport and not simply in racing cars. The Club very much wants to play its part in nurturing talent across the board in order to ensure that British drivers remain at the fore, both nationally and internationally, in years to come.\n\nIn addition to access to the Club and the opportunities for networking with the Members, the SuperStars will receive direct assistance with all aspects of professional motor sport. This will include help with physical and mental training, career guidance, team building skills, sponsorship advice, media and sales training, PR and marketing, motor sport seminars and workshops with BRDC Members. They will also gain significant benefit of media coverage that the BRDC SuperStars programme itself generates. Indeed, the Club’s endorsement of each young driver’s status as one of the very brightest prospects in motor sport is undoubted but hard to put a value on.\n\nThe SuperStars programme helps to strengthen links between young drivers and the Club, as well as reinforcing the relevance of the BRDC to the wider motor sport community.	http://cre8media.net/podcastfeeds/SuperStarsituneslogo2018.jpg
1327	http://cre8media.net/podcastfeeds/britishgt.xml	The Avon Tyres British GT Championship – Audio Podcasts	Matt Jones	The AvonTyres British GT championship showcases the most prestigious and stylish sportscar grid of any national motorsport championship in the world. The 2013 season will visit six UK venues with one international event held at the Dutch circuit, Zandvoort.\n\nFor the fans, the British GT Championship offers a spectacular motorsport experience. With glamorous supercars racing bumper-to-bumper, ground-shaking noise, breathtaking speeds and all the drama of pit stops and driver changeovers, the race experience is one not to be missed.	http://cre8media.net/podcastfeeds/gt2013.png
1328	http://cre8media.net/podcastfeeds/btcc.xml	Official British Touring Car Championship Interviews	Matt Jones	Informed interviews with all of the BTCC's stars, exclusive behind-the-scenes access and all the latest insight and reaction from the paddock.	https://cre8media.net/podcastfeeds/BTCCiTunes2020.jpg
1329	http://cre8media.net/podcastfeeds/cvqopodcasts.xml	CVQO Podcasts	Cre8media Ltd	CVQO is an education charity, accredited by Edexcel, City & Guilds and the Institute of Leadership and Management (ILM), that provides life-changing opportunities to young people and adult volunteers to improve their prospects in education and work through internationally recognised vocational qualifications. CVQO delivers a range of qualifications and encourages learners from all backgrounds and abilities including those with learning difficulties, special educational needs or physical disability. We are committed to giving more people equal access to better opportunities in life.	http://cre8media.net/podcastfeeds/cvqoitunes2015.jpg
1330	http://cre8media.net/podcastfeeds/kcdiscoverdogs.xml	Discover Dogs 2014 Podcasts	Matt Jones	Discover Dogs 2014 takes place between 8 - 9 November 2014 at Earls Court 1, London\n\nMeet and greet over 200 breeds of dog and find out about where to buy a dog, caring for your best friend and which breed is best suited to your lifestyle as well as great tips for training your canine buddy!\n\n\n\nSponsored by Eukanuba and Metro Bank, the event is expected to welcome over 26,000 visitors and 3,000 dogs over the two days of the show.\n\n\n\nThe event provides a fantastic opportunity for visitors to meet, greet and discover over 200 different breeds of dog, and learn all about the distinctive personalities, traits and looks of each breed and how to buy the perfect canine partner.	http://cre8media.net/podcastfeeds/dd2014.jpg
1331	http://cre8media.net/podcastfeeds/tomkimbersmith.xml	Tom Kimber Smith - Professional Race Car Driver, 3x Le Mans Winner 06,11,12, 2011 ELMS Champion	James Warnette	Tom Kimber-Smith is a highly successful British racing car driver who has established himself on both sides of the Atlantic.\n\nThe 28-year old’s career began in 1990 behind the wheel of a kart.  He graduated to cars in 1999 and won a “T-Car” saloon-car championship in 2000.  Since then, Kimber-Smith’s racing resume has been filled with accolades, including championships in British Formula Ford (2003) and Le Mans Series LMP2 class (2011) and three class wins at the 24 Hours of Le Mans, in the LMP2 class (2012 and 2011) and GT2 class (2006).\n\nThis year sees Tom go for his third successive LMP2 class title at Le Mans, back with Greaves Motorsport. In addition to this Tom is also competing for Core Motorsport in a Porsche 997 GT3 R in the American Le Mans Series, in tandem with outings in the European Le Mans Series LMP2 class for Greaves, and in the Grand Am series with 8 Star Motorsport.\n\nFor more information on Tom, visit: http://www.tomkimbersmith.com	http://cre8media.net/podcastfeeds/tomitunes.png
1366	http://crossborn.libsyn.com/rss	Crossborn	Rod Schorr	The preaching ministry of Calvary Chapel Old Towne in Orange, CA	https://ssl-static.libsyn.com/p/assets/c/a/6/4/ca64ab996d3d4752/Podcast_Crossborn_Logo.jpg
1334	http://creatingsuccesspodcast.com/RSS/tunes.xml	Creating Success	Mitchell Anthony	With an audience spanning over sixty countries and thousands of episodes downloaded each day, Creating Success features interviews with successful, creative people. Producer and host Mitchell Anthony keeps these informative and entertaining conversations flowing, so you get the most from listening. Want help building your creative career? Subscribe now.	http://www.creatingsuccesspodcast.com/Graphics/RSS/iT2008.jpg
1335	http://creation.podomatic.com/rss2.xml	CREATION MOMENTS MINUTE	CREATION MOMENTS MINUTE	Check the "Favorite Links" below to sign up for our daily email devotional!  Also below, subscribe via iTunes, Google+ or Yahoo!  Or get the RSS feed at the top of this page along with links to our Facebook and Twitter!  \n\nTo use this feature on your radio station, website, or podcast for FREE, contact darren@marlarhouse.com.\n\n\n***\n\n\n\n  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){\n  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),\n  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)\n  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');\n\n  ga('create', 'UA-52749039-1', 'auto');\n  ga('send', 'pageview');	https://assets.podomatic.net/ts/4c/93/45/darren33458/3000x3000_9457620.jpg
1336	http://creativecodingpodcast.com/?feed=podcast	The Creative Coding Podcast	The Creative Coding Podcast	Iain and Seb discuss the ins and outs of programming for creative applications	https://creativecodingpodcast.com/wp-content/plugins/powerpress/rss_default.jpg
1337	http://creativecommoners.net/?feed=podcast	Creative Commoners	creativecommoners@gmail.com (Chris Armstrong, Corey Bishop, Allison Dickson)	A weekly podcast for everyday people trying to maintain creative pursuits amid the demands of home, work, and family. Chris Armstrong is a master wordsmith with a head full of ideas. Corey Bishop is a budding game developer, tabletop gamer, and short story author. Allison M. Dickson is a speculative fiction author with several published stories and many more on the way. Each week will explore a particular topic about the creative process, with each host bringing their own flavor and experience to the mix, and plenty of witty and tangential banter to keep things fun.	http://creativecommoners.net/wp-content/uploads/2014/03/podcast-avatar-1400.jpg
1338	http://creativeendeavors.libsyn.com/rss/category/inspirations	Spot On Radio.com	Bridgette Mongeon	Spot On is a term from the U.K. that means absolutely correct or exactly what is needed and offers two channels\nInspirations/Generations and Creative Christians Podcast.	http://static.libsyn.com/p/assets/1/1/c/9/11c9edd43a61e140/spoton.jpg
1341	http://crederethewave.podomatic.com/rss2.xml	Credere: The Wave	A.R.		https://assets.podomatic.net/ts/62/bc/02/b-gian20/3000x3000_8056521.jpg
1343	http://creekside.org/podcast.php?pageID=13	Creekside Church	Creekside	Creekside Church is committed to communicating a relevant, practical  and biblical message that will add value and understanding to your life.	https://clovermedia.s3-us-west-2.amazonaws.com/store/bd/bd18f7c8-a262-4f98-9bee-32c4b628ff93/thumbnails/mobile/b61c1be9-25b8-4fa6-a9e7-9440641a5e20.png
1345	http://creepycorner.libsyn.com/rss	The Creepy Corner	The Creepy Corner	The Creepy Corner is a gritty new podcast with the intent to be raw and hilarious. We strive to be offensive in the best of ways and hope you enjoy guys who have been friends all of their lives talking about real stuff that really matters. At least to them.	https://d3t3ozftmdmh3i.cloudfront.net/staging/podcast_uploaded_nologo/7264599/e9df2cabd7dc91d8.jpeg
1348	http://cricketshow.libsyn.com/rss	World Cricket Show	World Cricket Show	A cricket podcast by two guys whose school team once got bowled out for 22, and the next week got bowled out for 13. And they never let it go. 'Acclaimed' - Financial Times	https://thumborcdn.acast.com/noggPU2Of1jOsEKMlsG8l55QabY=/1500x1500/https://acastprod.blob.core.windows.net:443/media/v1/29fcf1dd-b9de-4964-aed2-3215c9025dbb/13177629-1345541278794602-6808948792476884768-n-io4gefno.png
1351	http://crimprofall2011eveningprofgarland.classcaster.net/feed/	Crim Pro Fall 2011 Evening Prof Garland	\N		\N
1353	http://cristoentuvida.podOmatic.com/rss2.xml	Cristo en Tu Vida	Parroquia Inmaculada Concepción		https://cristoentuvida.podomatic.com/images/default/podcast-1-1400.png
1354	http://crit-iq.com/index.php/Podcast_Feed	Crit-IQ	Crit-IQ	Crit-IQ staff interview leading clinicians on topics of controversy and interest in critical and intensive care	https://www.crit-iq.com/images/icons/CritIQ_podcast_icon.jpg
1355	http://criticalmoment.libsyn.com/rss	Sincere Sarcasm	Francis Fernandez	A podcast where we talk about the nerdy geeky things in the world. Yep, that's pretty much every single freakin' thing around us, and that's what makes it awesome. From geeking out on movies, tv, science, philosophy, food, video games and anything epic and awesome, we nerd out to anything and everything.	https://ssl-static.libsyn.com/p/assets/6/1/6/8/6168919a16b44e82/Sincere_Sarcasm_large_text.jpg
1356	http://criticalslinky.podomatic.com/rss2.xml	Caprica Café	Andrew Morgan	http://capricacafe.blogspot.com/	https://assets.podomatic.net/ts/a8/3c/13/criticalslinky/1400x1400_601517.jpg
1357	http://criticalstrike.libsyn.com/rss	Critical Strike	Critical Strike	Critical Strike is formed by Josh, Kyle and Billy who fortnightly get together and basically talk about video games or celebrate one of our favorite things, video game music.	http://static.libsyn.com/p/assets/6/a/0/5/6a05f05352bdcfe2/csitunes.jpg
1358	http://crjunglistcrew.com/?feed=podcast	CRJunglist Crew	management@crjunglistcrew.com (podcast@crjunglistcrew.com)	Building an army, one Junglist at a time, since 1997...	http://crjunglistcrew.com/wp-content/uploads/2012/03/144podcast-logo.jpg
1360	http://crn.seesaa.net/index20.rdf	クロスロード西宮メッセージ	Copyright © 2012 Crossroad Nishinomiya. All rights reserved.	兵庫県西宮市のキリスト教会です。日曜礼拝は9:00、11;00、14:00の3回あります。赤ちゃんからキッズ、中高生、大学生のための学びの機会もありますので、ご家族連れでもお一人でもぜひ一度お越し下さい。阪急西宮北口駅の北西口から北へ徒歩2分、りそな銀行北側にあるエヴィータの森2Fです。エレベーターあり。詳しくはwww.crossroad-web.comをご覧ください。	https://crn.up.seesaa.net/image/podcast_artwork.jpg
1362	http://croncast.com/shows.rss	Croncast	Croncast - Betsy Shilts and Kris Smith	A series documenting a love story. Betsy and Kris narrate the life they share together, on the road, with strangers and the one with their kids in tow. These two will make you laugh like no other show. Croncast is now made in the woods at the gateway to the Poconos.	http://www.croncast.com/itunes-cover-1400.jpg
1364	http://crookidcurtgrhm.podOmatic.com/rss2.xml	CROOK-ID Curt GRHM	CROOK-ID Curt GRHM		https://assets.podomatic.net/ts/51/42/b6/crookidcurtgrhm/1400x1400_1962390.jpg
1365	http://crooner.podomatic.com/rss2.xml	La Cultura del Videojuego. Albert Murillo	Albert Murillo	Podcast en castellano creación de Albert Murillo.	https://assets.podomatic.net/ts/18/99/57/crooner/1400x1400_375688.jpg
1368	http://crosscountryskifun.com/podcasts/itunes_feed.xml	Cross-Country Ski Getaways	Jonathan Wiesel (contact@crosscountryskifun.com)	Hear about cross-country ski destinations – including ski trails, lodging, dining, and other winter activities available – with a representative of that particular Nordic ski area/ski resort and with comments from author/cross-country ski expert Jonathan Wiesel. More winter vacation/travel and cross-country skiing information is available at www.crosscountryskifun.com.	http://crosscountryskifun.com/podcasts/ccsgpodcastart.jpg
1372	http://crosspointcc.org/podcast.php?pageID=19	Crosspoint CC Podcast	Crosspoint Community Church	A podcast from Crosspoint Community Church in Eureka, IL.	https://clovermedia.s3-us-west-2.amazonaws.com/store/e1/e1cf7600-ae97-4932-acb5-b26923792f7f/thumbnails/mobile/ee82b8b6-2c3c-4faf-bb63-bd223bd5b5e6.jpg
1378	http://crossroadsbiblechurch.com/?podcast	Crossroads Bible Church Podcast		We exist to glorify God by making disciples of all peoples through the gospel of Jesus Christ	\N
1382	http://crosstimberstechapps.podomatic.com/rss2.xml	CrossTimbers TechApps Podcast	CrossTimbers TechApps	This podcast is new for all of us.  We will be posting newsletters, weather reports and a variety of other stuff.  So check us out and let us know what you think.	https://assets.podomatic.net/ts/63/9b/5e/crosstimberstechapps/1400x1400_627941.jpg
1388	http://cruiseradioshow.libsyn.com/rss	Cruise Radio	Doug Parker	Doug Parker gives weekly cruise news, ship reviews, money saving tips, answers your travel questions, and helps you make the most of your cruise vacation.	https://ssl-static.libsyn.com/p/assets/8/6/5/3/8653cd57e5043eab/cruiseradio_finallogo.jpeg
1392	http://crunkatlanta.podOmatic.com/rss2.xml	Atlanta Promoter's Podcast	Crunkatlanta	Get in Crunkatlanta Magazine - just email me - Crunkatlanta@gmail.com -->\n┌П┐(-_-)┌П┐!!!!! ITS the DAM MIXTAPE 2 - Follow your boy @CrunkatlantaMag on Twitter and IG	https://assets.podomatic.net/ts/71/d1/4e/crunkatlanta/3000x3000_12948660.jpg
1395	http://crystalradio.podbean.com/feed/	Crystal Radio	MC Crystal Radio	Malden Catholic High School Student Run Podcasts	https://djrpnl90t7dii.cloudfront.net/podbean-logo/powered_by_podbean.jpg
1396	http://cryztalnovie.podomatic.com/rss2.xml	Cryztal & Novie	Cryztal & Novie	Varje fredag surras det i den gröna skinnsoffan i vårat vardagsrum.	https://cryztalnovie.podomatic.com/images/default/podcast-4-1400.png
1397	http://csaladikor.podomatic.com/rss2.xml	Családi kör podcast	Kata, Zsolt	Kata, Zsolt és a gyerekek\nHetente megjelenő podcast, benne Apple hírekkel, családi történésekkel, film és zene ajánlóval, kultúra rovattal.\n\nCélunk bemutatni egy keresztény polgári család minden napjait. Öröm, bosszúság és hétköznapi történetek.	https://assets.podomatic.net/ts/e4/07/a1/butcher75/3000x3000_6182269.jpg
1398	http://csamways.podomatic.com/rss2.xml	Dj Ceejay's Podcast	Clive Samways	1 - Sukkerfry -  Diego Quintero - Mafia records\n2 - Say goodnight to the Bad guy - Avrosse - Original mix\n3 - Are your kisses dynamite - Ahmet Sendil - Avrosse Remix\n4 - Sneaky sounds - Da Fresh - Original mix\n5 - Freak La Technique - Jc Project - Jatay Remix\n6 - F**k off - Formatique - Manchester Underground Music \n7 - Sirena - Mehmoosh - Original mix\n8 - Belo Horizonti - Phunk investigation - Ahmet Sendil Remix\n9 - Fat Back Beat - Hugo Rizzo - Timmy Tommy Remix\n10 - Stronger - Droplex - Take off records\n11 - Murmer 03 - Dj Stom & Ash - Original mix\n12 - Rikki Tikki - Tony Kairom - Dani sbert Remix\n13 - Desire - Alex Dias - Veerus & Maxine Devine Remix\n14 - This Turbulent Priest - Beardyman - "I Done a Album"	https://assets.podomatic.net/ts/d4/42/6d/csamways/3000x3000_5663238.jpeg
1399	http://csbstijuana.podomatic.com/rss2.xml	CSBS Tijuana's Podcast	CSBS Tijuana	This is a podcast of CSBS Tijuana's ongoing lectures. Mainly a recourse for students in CSBS Tj, but also for public use and for anyone wanting to follow along and do your ow studies with us. Keep an eye out for some excellent lectures from Ron Smith, David Hansen, John Randerson, Cliff Davis, Brian Appelt, Plamena Williamson, Kerry Neve and much more.	https://assets.podomatic.net/ts/71/b9/1d/podcast41708/3000x3000_5039236.png
1400	http://cscamtf-puxian.podOmatic.com/rss2.xml	遵修普贤大士之德 - 净空法师	S C Chan		https://assets.podomatic.net/ts/55/e1/00/cscamtf-puxian/3000x3000_2051665.jpg
1402	http://csg.libsyn.com/rss	Centennial State Geocaching Podcast	Mrs. Beasley Omnimedia	A podcast about geocaching and other navigational games in Colorado and around the world	http://static.libsyn.com/p/assets/a/7/5/9/a759e959f4b164da/colorful-colorado.jpg
1403	http://csibri9.podomatic.com/rss2.xml	DJ CRIS.A Podcast	Cristiano Adriano		https://assets.podomatic.net/ts/53/13/79/csibri9/1400x1400_4801159.jpg
1404	http://csis.org/files/media/feeds/csisaudio.xml	The Truth of the Matter	CSIS | Center for Strategic and International Studies (podcasts@csis.org)	Many of us have questions about global issues and not a lot of places to turn to for reliable and thoughtful answers. In The Truth of the Matter, hosts Bob Schieffer and Andrew Schwartz breakdown complex policy issues of the day. No Spin, No Bombast, No finger pointing. Just informed discussion.	https://csis-prod.s3.amazonaws.com/s3fs-public/itunes_u/Podcast_TruthoftheMatter_cover_FINAL%5B2%5D_0.jpg
1405	http://csls.podOmatic.com/rss2.xml	Darwin or Design with Dr. Tom Woodward	C.S. Lewis Society	A presentation of the C.S. Lewis Society, Darwin or Design is a radio program hosted by Dr. Tom Woodward that airs at 5 p.m. on 570 WTBN in the Tampa Bay area. \n        \n        Darwin or Design addresses issues in apologetics and intelligent design bringing in world class experts in these areas on a weekly basis.	https://assets.podomatic.net/ts/21/ce/97/csls/pro/3000x3000_1111702.gif
1406	http://cslumberparty.libsyn.com/rss	Double Page Spread	Wendi Freeman	A podcast about comics, fandom and exploring the creative process.	https://ssl-static.libsyn.com/p/assets/3/e/8/5/3e852203f1755908/0.jpeg
1407	http://csnetwork.eu/podcast/feed.xml	Convergent Science Network Podcast	Convergent Science Network: by Prof. Paul Verschure	We can learn a lot from brains and bodies when making machines and robots. But reversely, building complex machine systems can also give ideas about how brains and bodies have implemented their functioning over the evolution of ages. This podcast discusses various themes and aspects in-between robotics, neuroscience, cognitive science, artificial intelligence, biology, and technology.	http://csnetwork.eu/podcast/images/itunes_image.jpg
1408	http://cspd.podomatic.com/rss2.xml	WM-CSPD August Institute 2011	Technology Runs Through It	Education conference held August 8-10 2011 on the University Of Montana Campus.	https://assets.podomatic.net/ts/09/99/b9/herbe82/1400x1400_4841432.jpg
1409	http://cspodcast.libsyn.com/rss	Adobe Creative Cloud TV	Terry White	Welcome to the Adobe Creative Suite Podcast with tips and tutorials by Terry White. Learn how to unlock the power and potential of the Creative Suite with the visual examples here. I will try to cover all the products evenly, but I do have a passion for InDesign and Photoshop.	http://static.libsyn.com/p/assets/c/f/7/5/cf75d26ed52028ca/Creative-Cloud-TV-3.jpg
1410	http://csspence321.podomatic.com/rss2.xml	This Broken World	C.S. Spence	A weekly video/audio podcast rewritten and read by C.S. Spence.  C.S. Spence is a philosophical entertainer that discusses a number of controversial issues including religion, animal rights, sex, and politics.  \n\nThis Broken World has no corporate connections, and is completely independent.  The program features listener comments and biting commentary.	https://assets.podomatic.net/ts/a3/0a/88/csspence321/3000x3000_5168144.jpg
1411	http://csuppodcast.podomatic.com/rss2.xml	C's Up Podcast	C's Up! Podcast		https://assets.podomatic.net/ts/f4/c2/33/csuppodcast/3000x3000_7898905.jpg
1412	http://csvsp.libsyn.com/rss	Chin Stroker VS Punter	Michael J. Parks	Art VS entertainment? Style over content? Schindler's List or Weekend at Bernie's?!! Two film fans in Birmingham, England. One is a chin stroker. The other is a punter. Discussion ensues....\n\nLeave us feedback at chinstrokervspunter@gmail.com\nVoicemail (US) 206-350-0293 or (Elsewhere) 001-206-350-0293	https://ssl-static.libsyn.com/p/assets/a/2/5/1/a25161b2efab060b/460_2673085.png
1413	http://ct-n.com/podcasts/campaign_10.xml	CT-N Covers CT Campaign 2010	Connecticut Network (ctnwebmaster@ct-n.com)	CT-N's Coverage of Connecticut's 2010 Political Season Campaigns and Debates	http://www.ctn.state.ct.us/podcasts/CT-N_iTunes.jpg
1416	http://ctfcoopcast.libsyn.com/rss	Chicken Thistle Farm CoopCast	Chicken Thistle Farm	Sharing our small farm stories and skills along our farming, gardening and homesteading journey.\nVisit the farm for an informative and sometimes irreverent tour through our garden, livestock pastures, chicken coop, beehive and greenhouse as we live - pasture to plate. \nFarming topics free range around pastured heritage pigs, broiler chickens and pastured eggs, heritage breed turkeys, an heirloom vegetable CSA and garden, high tunnel / hoop house / green houses, organic and traditional gardening, farm infrastructure, tractors, sustainable energy, being self sufficient, permaculture, food preservation, bees, beekeeping and even fence mending.	https://ssl-static.libsyn.com/p/assets/2/7/c/6/27c647d73bf9d852/CoopCast1400x1400.jpg
1417	http://cthulhu.jellycast.com/podcast/feed/2	Cthulhu on Parade!	cthulhu	A small group of friends get together every once in a while to play Call of Cthulhu over the internet. Sometimes, they record these sessions. This is the result. We hope you enjoy it.\n\nWith theme music by Kevin Macleod at http://www.incompetech.com.	https://cthulhu.jellycast.com/files/CoP2.png
1419	http://ctkb.seesaa.net/index20.rdf	続・ギタリストの想ふコト	Takeshi Murata	ギタリスト村田タケシのPodcastへようこそ。PVやインターネットTV、ラジオをお楽しみください。オフィシャルホームページ「椎茸“C-Take”工房」の内容にリンクしたものを中心に配信していく番組です。	http://ctkb.up.seesaa.net/image/podcast_artwork.jpg
1420	http://ctkcc.libsyn.com/rss	Christ the King Catholic Church	Christ the King Catholic Church	Welcome to the Christ the King Catholic Church Podcast Page! Christ the King is a charismatic personal parish of the Diocese of Lansing, located in Ann Arbor, Michigan. For more information about Christ the King Catholic Church, please go to our website, www.ctkcc.net.	https://ssl-static.libsyn.com/p/assets/5/9/4/0/59402a368bb70826/Holy_Spirit_from_CTK_window.png
1422	http://ctrlaltwow.podbean.com/feed/	Ctrl Alt WoW - World of Warcraft Podcast	Aprillian, Grand Nagus and Constraxx	The Podcast For Those of Us Who Love World of Warcraft and Love Making Many Alts. Aprillian, Grand Nagus and Constraxx discuss another week of playing World of Warcraft, Blizzard\\'s great MMORPG. This is a casual, non professional podcast. We do this for fun and for the WoW Community for free. We welcome listener\\'s contributions. Full Show Notes at http://ctrlaltwow.com	https://pbcdn1.podbean.com/imglogo/image-logo/88215/CAWRedLogo400sm.jpg
1424	http://cubiquedj.podomatic.com/rss2.xml	The Domenica Sessions	Cubique DJ	New Podcast By Cubique DJ	https://assets.podomatic.net/ts/e8/4c/83/podcast74916/3000x3000_12670353.jpg
1426	http://cudipeich.podOmatic.com/rss2.xml	JOSE CARTELLE's Podcast	JOSE CARTELLE		https://cudipeich.podomatic.com/images/default/podcast-3-1400.png
1427	http://cuffemandstuffem.jellycast.com/podcast/feed/2	CUFF EM' & STUFF EM' PODCASTS	cuffemandstuffem	CUFF EM' & STUFF EM' is a Cambridge based club night. For more info go to the Cuff em' & Stuff em' Facebook fan page.	https://cuffemandstuffem.jellycast.com/files/cuff%20em%20gray.png
1429	http://cuisinefromspain.libsyn.com/rss	Cusine from Spain	Marina Diez	Marina and Ben bring you all the best from one of the world's most exciting, natural, and healthy cuisines. Cooking tips, tapas, recipes, travel, vino and much more from the Madrid-based Spanish/English couple that also bring you 'Notes from Spain' and 'Notes in Spanish'.	https://ssl-static.libsyn.com/p/assets/5/8/e/a/58eaa6bdfbe564ac/Cuisine_iTunes_Graphic_1400x1400.jpg
1430	http://culdesac.wm.wizzard.tv/rss	Cul de Sac Animated Cartoons	RingTales	RingTales presents Cul de Sac animated cartoons.  Cul de Sac is the popular award winning comic strip created by Richard Thompson.  Cul de Sac features the Otterloop family lead by the indomitable four-year-old Alice.	http://static.libsyn.com/p/assets/e/1/f/9/e1f9a17a70b26426/culdesac_podcast.jpg
1434	http://cultivator.podomatic.com/rss2.xml	Cultivator's Podcast	Cultivator		https://cultivator.podomatic.com/images/default/podcast-1-1400.png
1437	http://culturevultures.podomatic.com/rss2.xml	Culture Vultures Podcast	Culture Vultures Radio	Join hosts Dirk Belligerent and Otto the Autopilot as they pick over the remains of pop-nerd-media culture with inimitable wit and wisdom. (Part of the PodcastDetroit.com network.)	https://assets.podomatic.net/ts/dd/17/0f/dirkbelig/3000x3000_12310664.jpg
1438	http://culturewedge.libsyn.com/rss	If It Bleeds, We Can Kill It	Trev and Byrd	We're pretty much the Mos Eisley of podcasts.  Just a wretched hive of scum and villainy who live in dank dwellings talking about anything and everything from a nerdy perspective.  Sometimes it’s entertaining…maybe.  No promises.	https://ssl-static.libsyn.com/p/assets/4/6/f/1/46f189b0a6f9e553/UPDATEDIFITBLEEDSLOGO.png
1446	http://curaloco.podOmatic.com/rss2.xml	Duo Benítez Valencia	mauricio jaramillo	Musica nacional del Ecuador con el Duo Benitez Valencia	https://assets.podomatic.net/ts/bb/60/6b/curaloco/3000x3000_2300482.jpeg
1447	http://curaloco3.podbean.com/feed/	Musica del Duo Benitez Valencia	Duo Benitez Valencia	Musica Nacional del Ecuador, Duo Benitez Valencia, Album Balcon Quiteño	https://pbcdn1.podbean.com/imglogo/image-logo/11979/139812269_adcb0023de_o.jpg
1448	http://curaloco6.podbean.com/feed/	Luis Alberto "Potolo" Valencia	Luis Alberto "Potolo" Valencia	Musica Nacional del Ecuador, Interpretada por Luis Alberto Valencia Cordova, "Potolo", Quito-Ecuador	https://pbcdn1.podbean.com/imglogo/image-logo/32555/logo.jpg
1449	http://curaloco8.podbean.com/feed/	Duo Benitez Valencia	Duo Benitez Valencia, Curaloco	Reliquias Musicales del Duo Benitez Valencia, grabaciones de HCJB, Introduccion a cada cancion de parte de Gonzalo Benitez	https://pbcdn1.podbean.com/imglogo/image-logo/77971/Duo_Benitez_Valencia.jpg
1451	http://cuso-vso.mypodcastworld.com/rss2.xml	Cuso International West	Cuso International	At Cuso International, we believe we are changing the world, one volunteer at a time. That’s because volunteering can be transformative for both\r\nthe overseas communities and\r\nthe volunteers themselves.\r\n\r\nEach year, we send hundreds\r\nof global citizens to work on\r\ncollaborative development\r\nprojects in many\r\ncountries around the world.	http://www.mypodcastworld.com/pubcast/download/attachment_id/5027/attachment_name/cuso_logo.jpg
1454	http://cut-killer-radio-podcast.backdoorpodcasts.com/index.xml	CUT KILLER	Cut Killer	Le podcast radio exclusif du Cut Killer Show [N°1 FM],le samedi de 22h à minuit en direct sur Skyrock.\nChaque semaine,retrouve les dernières bombes Rap et Rnb du moment remixés par Dj Cut Killer.	http://cutkiller.backdoorpodcasts.com/uploads/items/cutkiller/cut-killer-official-radio-shows-podcast.jpg
1458	http://cuups.libsyn.com/rss	The CUUPS Podcast	David Pollard	The CUUPS Podcast explores the world of Earth-Centered Spirituality and UU-Paganism as it is lived in over 1,040 UU Congregations across North America. Includes interviews, music and happenings from CUUPS members and chapters across the US with occasional info from our sister organizations the Unitarian Earth Spirit Network in the UK, and Six Source in Canada.	https://ssl-static.libsyn.com/p/assets/9/c/b/5/9cb533246018bcbd/ITunesPodcast.png
1460	http://cw-filme.eu/podcast/Podcast_von_Marco/podcast.xml	Vectorworks Modelling Podcast	ComputerWorks	Vectorworks ist das ideale CAD-Programm fürs 3D-Modellieren und 3D-Planen. Hier lernen Sie anhand von Beispielen, wie Sie in Vectorworks einfache Entwurfsmodelle oder exakte Präsentationsmodelle erstellen, die Sie als Grundlage für Visualisierung oder Herstellung verwenden können. Die Filme sind Ergebnisse unterschiedlichster Aufgabenstellungen wie zum Beispiel Entwürfe von Architekturstudenten oder Produktdesignern.	http://cw-filme.eu/podcast/Podcast_von_Marco/178x118_3D_Modellingfilme-1.jpg
1461	http://cwblogcast.hartmannetwork.libsynpro.com/rss	The Creating Wealth Show Blogcast	Jason Hartman	This is a short professional reading, audio blog or blogcast from the JasonHartman.com blog.  You'll learn how to survive and thrive in today’s economy as business and real estate investment guru, Jason Hartman shows you innovative ways to "game the system" relating to the American economic mess, Wall Street scams, mortgage meltdown, inflation induced debt destruction, deflation and monetary policy. Jason shares his no-hype investment strategies for REO's / foreclosures, auctions, lease options, land contracts, mobile home parks, self-storage facilities, rental apartments, office, retail, industrial, tax liens, loan modifications, credit repair and commercial real estate. Jason Hartman is a self-made multi-millionaire with years of financial experience. He currently owns properties in several states and has been involved in thousands of real estate transactions. Subscribe now for free to learn how to follow in Jason's footsteps for a more abundant life.	http://static.libsyn.com/p/assets/4/d/6/5/4d656924a0d136fd/CWB.jpg
1464	http://cworm.libsyn.com/rss	Cultural Wormhole	Cultural Wormhole	The Cultural Wormhole Podcast is the home of X-Nation, a podcast that focuses on Marvel's Merry Mutants, the X-Men. The C-Worm Podcast will also be the home of various shows that focus on all aspects of pop culture such as television, movies, comic books, video games, and music.	https://ssl-static.libsyn.com/p/assets/9/a/9/a/9a9acb54857a52a8/Logo.jpg
1465	http://cx.nxpress.net/podcast/siren.xml	居酒屋サイレン	\N	2006年2月11日（土）全国東宝洋画系ロードショー「サイレン」の、他では聞けない裏話をポッドキャストでお届けします。	\N
1466	http://cx4u.podspot.de/rss	Der Podcast zu den oldenburger gastagen		In regelmässigen Videopodcasts informieren wir Sie künftig interaktiv über die Ereignisse und Neuigkeiten rund um den Fachkongress und die Fachmesse. In den Beiträgen erfahren Sie jeden Monat mehr über Hintergründe der oldenburger gastage, das Kongressporgramm, die Messeaussteller und natürlich über die aktuellen Themen der Gasbranche.	\N
1467	http://cyberlaw.stanford.edu/podcasts/podcast_rss.xml	Center for Internet and Society	Stanford Law School Center for Internet and Society	The Center for Internet and Society (CIS) is a public interest technology law and policy program at Stanford Law School that brings together scholars, academics, legislators, students, programmers, security researchers, and scientists to study the interaction of new technologies and the law and to examine how the synergy between the two can either promote or harm public goods like free speech, privacy, public commons, diversity, and scientific inquiry. The CIS strives as well to improve both technology and law, encouraging decision makers to design both as a means to further democratic values.	http://cyberlaw.stanford.edu/podcasts/frond-CIS.jpg
1468	http://cyberliege.be/DIVERS/podcast/index.xml	CyberLiège pour Liege et sa province	Coumanne (contact@cyberliege.be)	actualité et petites annonces gratuites pour Liège et sa province	http://www.cyberliege.be/DIVERS/cyblg/cyberliegebleupetit.gif
1469	http://cybernautscast.wordpress.com/feed/	The CyberNauts Cast Podcast	\N	Defenders of Anime, Manga and Video Gamers of The Universe	https://secure.gravatar.com/blavatar/3986f90e2b668098bfb8ead021132209?s=96&d=https%3A%2F%2Fs0.wp.com%2Fi%2Fbuttonw-com.png
1470	http://cyfieldx.podomatic.com/rss2.xml	Rock Creek Radio	Rock Creek Radio	MD US Dead air.	https://assets.podomatic.net/ts/55/59/86/accessv/3000x3000_14268683.jpg
1471	http://cygarrick.podomatic.com/rss2.xml	Cy Garrick's Back To Basics Podcast	Cy Garrick	Making Health and Fitness simple so dads and moms can be at their best.	https://assets.podomatic.net/ts/f7/d7/1d/cygarrick/1400x1400_7351483.jpg
1472	http://cyktrussell.libsyn.com/rss	RunRunLive 4.0 - Running Podcast	Chris Russell	Welcome to the Run-Run-Live 4.0 Podcast!  - This podcast celebrates the transformative power of endurance sports.  \nThis is the next generation follow up to the RunRunLive 2.0 Podcast. \nThis show is a thoughtful, interview-based format that explores the connection between running, and endurance sports in general and your physical and mental health. \nAll episodes, show note, links and previous show iterations can be found at www.runrunlive.com	https://ssl-static.libsyn.com/p/assets/b/b/5/5/bb55a947894378d4/RunRunLive_WithText-itunes.jpg
1473	http://cynicalthinktank.podbean.com/feed/	360 Vegas	360 Vegas LLC	Las Vegas News, Reviews, Deals, Coming Attractions & Vintage Vegas segments that look at the people, resorts and events in history that make Las Vegas the greatest. WARNING: the host enjoys doing the show and laughs a lot as a result. If you don't like that, don't listen. We don't care.	https://pbcdn1.podbean.com/imglogo/image-logo/263668/360Vegas_1300x1300_dirty.jpg
1477	http://czech.podomatic.com/rss2.xml	Czech's podcast	Czech teacher		https://assets.podomatic.net/ts/2c/e7/9b/czech/1400x1400_606212.jpg
1551	http://danschorr.hipcast.com/rss/crime_and_justice_with_dan_schorr.xml	Crime and Justice with Dan Schorr	Dan Schorr	Tackling major topics and cases with leading figures in the world of criminal justice.  Dan Schorr is a former Inspector General for the City of Yonkers and criminal prosecutor in Westchester County and New York City.	https://danschorr.hipcast.com/albumart/1000_itunes_1602870609.jpg
1479	http://d-jamie.podOmatic.com/rss2.xml	Jamie Hammond's Podcast	Jamie Hammond	Monthly Progressive & Uplifting podcasts from London based DJ, Jamie Hammond. Featuring the latest in progressive, tribal & euphoric house. You can catch me at one of my residencies\n\nPopcorn - Heaven\nSuperMartXe London\nBeyond London\nPacha London\nLo Profile London\nMuccassassina Rome\nThe Week Sao Paulo \n\nTo keep in contact & up to date with my gigs/info please "Like" my new DJ page\nhttps://www.facebook.com/jamiehammondmusic\n\nYou can also subscribe via iTunes\nhttp://itunes.apple.com/gb/podcast/jamie-hammonds-podcast/id321916166\n\n\nBookings: jamie-hammond@hotmail.co.uk	https://assets.podomatic.net/ts/00/c0/e5/d-jamie/3000x3000_7636564.jpg
1480	http://d-mc.ne.jp/blog/dmc/?feed=rss2	D-mc Podcast&Blog	\N	D-mediaCreations制作事例や日常風景ログ。	\N
1482	http://d.hatena.ne.jp/fmgig/rss2	京都のミニFM＆インターネットラジオ fm GIG スタジオ日記	fmgig	\N	\N
1483	http://d.hatena.ne.jp/hkpodcast/rss2	heatwave_p2p & kskktk's Podcast	hkpodcast	\N	\N
1484	http://d.hatena.ne.jp/whitestoner/rss2	白石昇藝道馬鹿梵馬鹿梵梵。หินขาว มังกรบิน WHITESTONE Risin'	whitestoner	のぼるちゃんのはてなブログ。	\N
1487	http://da-bands.podspot.de/rss	www.da-bands.de	Radio Darmstadt	Die Platzierungen der Darmstadt Hitparade	\N
1488	http://da-rum.podspot.de/rss	da-rum - Podcast-Magazin	Claus-Uwe Rank	Monatliche Podcast-Magazin für Darmstadt und die Region.	\N
1489	http://da.azadiradio.org/podcast/?count=50&zoneId=2152	مربای مرچ - رادیو اروپای آزاد/ رادیوآزادی	رادیو آزادی	پادکاست چیست؟\nپادکاست یک و یا مجموعهء از فایل های دیجیتال صدا و یا ویدیو می باشد که توسط شبکهء انترنت از طریق سندیکیشن (syndication) که یک شیوهء اشتراک است، توزیع می شودد.\n این فایل ها را می توان در وسایل قابل انتقال میدیا و یا کمپیو تر های شخصی، مشاهده کرد و یا هم شنید.\nاستفاده کننده انترنت می تواند برنامه های را مشاهد کرده، یا بشنود که حسب تقاضای وی بصورت اتوماتیک از طریق شبکهء انترنت به وسیلهء میدیای دلخواه وی داونلود (download) می شوند.\n\nاصطلاح پادکاست از ترکیب کلمهء آی پاد(iPod) که وسیله قابل انتقال میدیا اپل کمپیوتر(Apple Computer) است و واژهء نشرات(broadcast) ساخته شده است.	https://www.rferl.org/img/podcastLogo.jpg
1490	http://dabearsblog.podomatic.com/rss2.xml	Da' Bears Blog's Podcast	Da' Bears Blog	Interviews, commentary and general mischief about the one and only Chicago Bears. Bear down, Chicago Bears.	https://dabearsblog.podomatic.com/images/default/podcast-1-1400.png
1491	http://dachief.podomatic.com/rss2.xml	Da Chief	Da Chief	Da Chief  is a North American rapper, writer and entrepreneur who was born in Methuen Massachusetts in 1976. At the age of 14 years old Da Chief started freestyle rapping with his brother in law who became his mentor.  In 2000 Da Chief opened Money Matters Productions. In 2002 he performed at the Spanish Festival in Lawrence Massachusetts. He released 2 albums on the streets with the label.\n           In 2004 Family Affairs Records was founded and released 3 records on the streets thus far. Da Chief is responsible for bringing Tony Sunshine, Maino, Opera Steve, Prospect and Terminology to many events in New England.  In 2010 Family Affairs Records  opened Insight Studio in Manchester, New Hampshire. Currently Da Chief is in the process of releasing his long awaiting and very much anticipated LP which will be soon titled. For booking and collabors contact us at dachiefmusic@gmail.com	https://assets.podomatic.net/ts/a0/4d/5a/dachiefmusic/1400x1400_3622109.jpg
1494	http://daddyfridge.podomatic.com/rss2.xml	daddyfridge's Podcast	daddy fridge		https://daddyfridge.podomatic.com/images/default/podcast-2-3000.png
1497	http://dadstuff.podbean.com/feed/	dadstuff	Craig Daliessio	A daily (M-F) podcast full of wisdom, advice, encouragement, and hope for single dads. Just a few minutes gets you through the day!	https://pbcdn1.podbean.com/imglogo/image-logo/526263/Me.jpg
1503	http://dagger.podOmatic.com/rss2.xml	Team D's podcast	Team Dagger	Weekly updates about the company, the whitewater team, boats, boating, and general information..\n\nWe will post 2 versions of each Podcast: A-audio and V-video...\n\nEnjoy and stay tuned!	https://assets.podomatic.net/ts/02/ab/b7/dagger/1400x1400_605311.gif
1504	http://dahairstyla.podspot.de/rss	Da Hairstyla´s Pod-Schnitt	dahairstyla	Sinn und Irrsinn	\N
1505	http://daikanyamachannel.seesaa.net/index20.rdf	代官山 daikanyama Channel	代官山手伝人　Teddy	代官山の魅力がいっぱい！ 〜代官山を愛する人達の情報番組〜	http://daikanyamachannel.up.seesaa.net/image/podcast_artwork.png
1508	http://dailyfreshjuice.net/feed/podcast/	Daily Fresh Juice	info@dailyfreshjuice.net (Daily Fresh Juice)	Daily Fresh Juice Renungan Harian Katolik Menyejukkan dan Menyegarkan	http://dailyfreshjuice.net/wp-content/uploads/powerpress/podcast.jpg
1512	http://dailysession.com/?feed=podcast	DAILYSESSION » Dailysession.com	dailysession		http://dailysession.com/Images/Itunespic.jpg
1517	http://damagedhearing.podOmatic.com/rss2.xml	DAMAGED Hearing: The Official Radio Show	Louis Fowler	An extension of the DAMAGED Media Empire, "DAMAGED Hearing" features all the colorful characters and hilarious guests you've come to know and tolerate, as well as new music from cool indie artists you should know about. And don't forget the special, exclusive "DH Presents" podcast-only episodes! More bang for your non-existent buck!	https://assets.podomatic.net/ts/19/6f/81/damagedhearing/1400x1400_4132093.jpg
1518	http://damagedviewing.podomatic.com/rss2.xml	DAMAGED Viewing (Vol. 2)	Louis Fowler	DAMAGED Viewing is a weekly movie podcast, but instead of the same ol' long-winded critical discussions you're used to, we tend to talk about how the films we feature have affected us as people, for better or worse, through as many amusing tangents as possible.\nHosted by award-winning film critic Louis Fowler and guest-spots from some of the best pop-culture critics on the web, DAMAGED Viewing is a hilarious foray into the more personal side of cinematic geekery.	https://damagedviewing.podomatic.com/images/default/podcast-2-3000.png
1519	http://damagician78.podomatic.com/rss2.xml	DA MAGICIAN's Podcast	DA MAGICIAN	DA MAGICIAN's Open Format Podcast	https://assets.podomatic.net/ts/9a/df/64/jjmobiledjs/3000x3000_12897497.jpg
1520	http://damedameyo.seesaa.net/index20.rdf	MCよっちゃんの笑っちゃダメダメよ〜	よっちゃん	東京で活動するMCよっちゃんが最近あったおもしろいことを発信！	http://damedameyo.up.seesaa.net/image/podcast_artwork.png
1571	http://dartmed.dartmouth.edu/podcast/insidedm.xml	Inside Dartmouth Medicine	Dartmouth Medicine magazine	"Inside Dartmouth Medicine" is a series of web-extra interviews produced by Dartmouth Medicine magazine, exploring the art and science of medicine at Dartmouth Medical School and Dartmouth-Hitchcock Medical Center.	http://dartmed.dartmouth.edu/podcast/insideDM_012907.jpg
1521	http://dameshek.libsyn.com/rss	NFL: The Dave Dameshek Football Program	Mark Brady	<p>Dave Dameshek sets his gaze on the NFL landscape to analyze, celebrate and - when necessary - offer improvements to America’s true national pastime from a true fan’s perspective. Dave is frequently joined by players, as well as his NFL Network regulars to talk about the game of football and perhaps more importantly, the game called life. On this podcast, nothing is off-limits... Except some stuff.</p>	https://nfl-od.streamguys1.com/nfl/20200723133208-6c5ffc291e76c07c6b2011d1798ab72dda049898428b190a7c584128aedf48d0ee885c16a0f46cb2a902c5b82f3c19f45b92472a04a587b2494027ac17a1c99b.jpeg
1525	http://danagould.libsyn.com/rss	The Dana Gould Hour	Dana Gould	Comedian Dana Gould takes a look at our world... through his eyes... for your benefit. Joined by fellow comedians and other interesting people with a focus on the weird and the real. Conversation. Music. Monologues. With Ken Daly, Andy Paley and more.	https://ssl-static.libsyn.com/p/assets/0/d/9/1/0d91bc29292eb60f/DGH_3000x.jpg
1528	http://dancehallnews.libsyn.com/rss	Gibbo Presents - Dancehall & Reggae News	Chris Gibson	Dancehall, reggae and sound system culture related interviews.	https://ssl-static.libsyn.com/p/assets/f/b/0/c/fb0c0e1dc0ca6e66/dj_gibbo_FINAL-02_square.jpg
1529	http://danceoneggshells.podomatic.com/rss2.xml	DOE Podcast - deep house, nu disco, indie dance, minimal, tech	Henri Freres	This podcast will be served twice monthly. Hints of vocals, sultry basslines, and crisp highs to get you through anything. Dance, socialize, drive, ride, or dine. I will be alternating with guests and myself for each show, so please stay tuned.	https://assets.podomatic.net/ts/1a/55/ca/danceoneggshells/3000x3000_8595801.jpg
1531	http://dancingwithelephants.libsyn.com/rss	Dancing With Elephants	Greg	Dancing With Elephants is a weekly, family-oriented podcast magazine from Chicago.  Hosts Greg, Tonya, Nikolai (age 8) and occasionally Caleb (age 6) discuss current events and review podcasts, books, computer games, movies, and television shows affecting today's 'trying-to-juggle-it-all' family.  A couple of personal family stories and a featured Podsafe song round out the show.  The way we see it: "Life's always gonna be a three ring circus, so you might as well enjoy it."	http://static.libsyn.com/p/assets/e/9/5/2/e952c9628dc04990/DiscoElephant_Final_copy.jpg
1534	http://dangagnon.podomatic.com/rss2.xml	Dan Gagnon gratuitement	Dan Gagnon	Dan Gagnon gratuitement est un podcast d'interviews d'humoristes en (pas) live de mon appart' à Bruxelles. Une heure avec des humoristes connus (parfois par peu de personnes) où personne n'est obligé d'essayer d'être drôle à toutes les 20 secondes. Ni de poser des questions trouvées sur Wikipédia. On discute simplement pendant une heure d'une passion commune, l'humour. En passant en revue le parcours, les échecs, les succès et les ambitions de l'invité. Car contrairement à ce qu'on pourrait croire, ils ne sont pas tous cons les humoristes. (Pour ceux qui connaissent Marc Maron, oui, vous avez raison. J'ai effectivement de la chance qu'il ne parle pas français.)	https://assets.podomatic.net/ts/47/7f/5a/gagnon-daniel/3000x3000_7382612.jpg
1535	http://dangerdog.wm.wizzard.tv/rss	Danger Dog	Libsyn	Nipping at the heels of podcasting is our favorite furry friend.  Watch the fun as the ordinary leads to extraordinary adventure from the perspective of "man's best friend". The show was originally based on the playful antics of a new pet dog with episodes capturing the joy of discovery with a few surprises. This popular show now includes a variety of beloved pets as more "furry friends" guest host to share in the amusement!  There is something for everyone! Join in the fun!	http://static.libsyn.com/p/assets/7/2/f/b/72fba2b35a17f702/dangerdog_av1400m2.jpg
1536	http://dangerzoneradio.podomatic.com/rss2.xml	Danger Zone Radio	Danger Zone Radio	The Danger Zone Radio Show is known as the UNSIGNED ARTISTS NETWORK providing radio play & interviews for upcoming talent worldwide. Unscripted comedy and spontaneous , awkward moments living up to the motto 'NO ONE IS SAFE' Tune In Wednesdays 6pm pst for Live  Listen on www.thedangerzonemedia.com	https://assets.podomatic.net/ts/1b/b4/32/slaporskip/3000x3000_6113420.jpg
1537	http://dangrn77.podomatic.com/rss2.xml	Surreal Grotesque Podcast: Stories of the Strange and Psychotic	Daniel Gonzales	A podcast featuring stories from Surreal Grotesque magazine, a free online pdf mag at www.surrealgrotesque.com. They are a publisher of strange, surreal and downright freaky horror fiction. They can also be found on Facebook at www.facebook.com/thesurrealgrotesque or on Twitter @realgrotesque.  If you like authors like Stephen King, Clive Barker, Ray Bradbury, Jack Ketchum, Christopher Rice, Douglas Clegg, this is the place for you!	https://assets.podomatic.net/ts/d4/6b/c3/dangrn77/3000x3000_7697011.jpg
1539	http://danielcabrera.podomatic.com/rss2.xml	Music Box Podcast (Dj Darian)	Daniel Cabrera	Welcome to the Music Box podcast, Where I present the Weekend Session & the Trance Journey every Weekend. Stay Tune. \n\nPeople who love Electro House, Big Room, Trance, Uplifting Trance & More. take a listen to the Music Box Podcast.\n\nTwitter @DKSAO117\nSoundcloud cabri117	https://assets.podomatic.net/ts/dd/00/0e/danielcabri/0x0_9077648.jpg
1540	http://danielfalkenbergmusic.podomatic.com/rss2.xml	Daniel Falkenberg's Podcast	Daniel Falkenberg		https://assets.podomatic.net/ts/fb/7a/80/danielfalkenbergmusic/3000x3000_9014854.jpg
1541	http://danielkristopherre.podOmatic.com/rss2.xml	daniel kristopherre's 'We Are...' Podcast	daniel kristopherre	Rooted in house music, but could be any style.  Tune in, and dance on.	https://assets.podomatic.net/ts/74/49/96/danielkristopherre/3000x3000_3197233.jpg
1542	http://danielpedj.podomatic.com/rss2.xml	BCN. Deluxe Music	Daniel Pé	The enthusiasm and rigor make a career of Daniel Pé in the world of music. Always look beyond the horizon mail, is charting a way to where her feet want to take ...\n\n• The stage of its inception: the Costa Brava his birth as a dj clicking Funky, R & B and 80's in First Class (Empuriabrava), Disco Viva (Empuriabrava) and City Arms (Roses).\n\n• He has been resident in: Xarai (Palafrugell) and Passarel.la (Empuriabrava)\n\n• In 2011 begins at the scene of House of the hand of Gabriel Cubero, Dj and producer recognized.\n\n•\tIn 2013 joins Plastic (Academy official Dj's from Barcelona) where it starts to handle new techniques Dj and production of the hand of great professionals like Jordi Carreras, Daniel Trim, Uner, Albert Neve, David Gausa Obek, Andre Vicenzzo ..	https://danielpedj.podomatic.com/images/default/podcast-3-3000.png
1544	http://danieltrapala.podbean.com/feed/	IESP Central	Iglesia Evangelica San Pablo	Los mensajes de la Iglesia Evangélica San Pablo Central	https://pbcdn1.podbean.com/imglogo/image-logo/443633/Logo_Central_Grande.jpg
1547	http://danmooji.podbean.com/feed/	Dan Moo Ji	danmooji	단순, 무식, 쥐랄~팟케스팅 라디오!  여기는 매릴랜드!!	https://pbcdn1.podbean.com/imglogo/image-logo/308153/image.jpg
1549	http://dannydx.podomatic.com/rss2.xml	Danny Dx	Danny Dx	Geliebt und gehasst!\nVerehrt und beneidet!\nEtweder du läufst mit Ihm oder gegen Ihn!\nWerde Fan oder bleib Hater!\nDas ist echter Deutscherrap	https://assets.podomatic.net/ts/ef/6d/02/podcast1091683163/3000x3000_4988597.jpg
1552	http://dansefarm.podomatic.com/rss2.xml	DFR	AR/KVB	With his hit podcast Danse Farm Radio, AR/KVB has proven that having the foresight to look backward can provide a plentiful harvest. With scores of celebrity guests, meticulous blends, and a knack for the cross-pollination of genres, DFR offers the freshest beans for the cultivation of your iCrop. \n\nBroadcast from The VC Cupboard in the beautiful City of Roses, tune in for the podcast party of the millennium... let your hare down.	https://assets.podomatic.net/ts/18/db/fe/dansefarm/3000x3000_15050007.jpg
1553	http://dansmabulle.podomatic.com/rss2.xml	Dans ma bulle Podcast	chandleyr	Replay emission dans ma bulle: ---->http://dansmabullereplay.tumblr.com/\nhttp://www.buzzmygeek.com----> infos, critiques...	https://dansmabulle.podomatic.com/images/default/podcast-3-3000.png
1554	http://danw547.podomatic.com/rss2.xml	Half-Assed Gamers Podcast	Dan Wrigley	3 Youtube "legends" just shootin' the shit about videogames.	https://danw547.podomatic.com/images/default/podcast-1-1400.png
1555	http://danyb.podOmatic.com/rss2.xml	TSoNYC® - The Sound Of New York City®	TSoNYC® - The Sound of New York City®	"The Sound of New York City" is a project born from the idea of its founder back in 2006 to encourage the rediscovery of the Disco Sound, including Soul - Funk - House, while at the same time make use of my extensive vinyl collection, much of which was gathered from underground sources, dating back to 1975. \n\nIn December 2009 the initial project was transformed into a live, 24/7 web radio station:\nTSoNYC™ The Sound of New York City™. The station's programming is based on the history of New York's clubs like “Paradise Garage” and “The Loft”, with their protagonists Larry Levan and David Mancuso, as well as Detroit and Chicago with “The Warehouse” and “The Gallery”, where Frankie Knuckles and Ron Hardy spread their style. The TSoNYC sound includes Nu-Disco and Deep House, showcasing DJ contemporaries such as Moodymann, Danny Krivit, Theo Parrish, LTJ experience, and others who are now contributing to the rediscovery of this immortal music.\n\nThe growing interest for this genre of music is being demonstrated as our site last year reached more than 14 thousand visitors, with tremendous audiences tuning not only within the USA and Canada,but also in Germany, Greece, Japan, Russia, France, Poland, England and Italy as well.\n\nBe sure to check out our podcasts and new track releases on Facebook, iTunes and Podomatic.\n\nEach week international guest DJs perform exclusive mixes. Among some of the latest to be featured: Ashley Beedle (UK), Disco Dave (Sweden), Gilo (Italy), Gino Grasso (Italy), Jeff White (Chicago, USA), danyb (Italy), Joseph Colbourne (Boston, USA), Ly Sander (Switzerland), Nicholas (Italy), MichiNYC (Italy), Sauro Cosimetti (Italy), Soulparanos (France), Soulseduction (Greece), Katzuma (Italy), and many others will.\nThese then become mix podcasts that are downloaded more than 3500 times per month on average.\nThe radio can be reached directly from the website or the iTunes Radio under the category 70's music and Electronica\n\nStay Tuned...	https://assets.podomatic.net/ts/d2/61/94/danyb/pro/1400x1400_8955308.jpg
1556	http://danyd.podomatic.com/rss2.xml	Dany D's Podcast	Dany D	Passionné par la musique électronique depuis plus de 10 ans, en passant de l'électro à la deep house et la house, Dany D trouve un penchant, par la suite, pour la minimale et la techno. C'est en 2007 qu'il s'intéresse à la M.A.O et au Djing en mixant dans différents bars de Paris et en se produisant sur les radios de Tropique fm et Wafradio. C'est cette passion qu'il souhaite aujourd'hui partager et élargir.	https://danyd.podomatic.com/images/default/podcast-4-3000.png
1558	http://darictone.podomatic.com/rss2.xml	Ali Foomani's Podcast	Ali Foomani	1.Love Comes Again –Tiesto (Hardwell Rework) \n2.Future Folk –Tommy Trash \n3.Speed-Jerome lsma Ae \n4.Tornado- Tiesto &Steve Aoki \n5.Alejandro-Lady GaGa (Skrillex Remix) \n6.Happy Violence-Dada Life \n7.Cobra-Hardwell \n8.Le Bump-Yolanda Be Cool feat.Crystal Waters \n9.Stars Come Out-Zedd \n10.La Musica Me Hace Mas Feliz –Manuel De La Mare \n11.Oversexed – Format B \n12.Deal With It-Kill The Noise \n13.So Much Love-Pink Fluid(John Jacobsen & G-Martinez Remix) \n14. Were High (Dj Madskillz Remix)- Tish \n15. Krakra Hurricane (Original Mix)- Dj Lion Ft. Luigi Rocca \n16. Gravy-Ministers De La Funk (Erick Morillo, Harry Romero, Jose Nunez) \n17. Between the Rays -Ørjan Nilsen	https://assets.podomatic.net/ts/50/31/69/ali-fomn/3000x3000_5851974.jpg
1559	http://darkcrazy.libsyn.com/rss	TV Ate My Dinner	Sean Gilbert, Greg Starks, Brooks Robinson	Can life lessons we learn from movies prepare us for the end of civilization?  Is Harry Potter the new Star Wars?  Has modern science fiction lost its way?  Are housewives ruining American television?\n\nExplore these questions and many others with Sean Gilbert, Brooks Robinson and Greg Starks in TV Ate My Dinner, the podcast that brings you the finest in opiniontainment when it comes to movies, TV and media issues.  It could also mean the difference between living and dying if you ever find yourself staring down the business end of a zombie bite, so this is one show you can't afford to miss!	https://ssl-static.libsyn.com/p/assets/c/3/a/7/c3a7b997a587de7a/TV_cover.jpg
1561	http://darklightpodcast.jellycast.com/podcast/feed/2	The Darklight drum n bass Podcast	Oliver Drury	::UPDATE - THE DARKLIGHT PODCAST WILL BE GOING OFFLINE FOR THE NEXT 6 MONTHS - I NEED TO CONCENTRATE ON MY EDUCATION AND OTHER PROJECTS FOR THE NEXT HALF YEAR - THANKS FOR YOUR SUPPORT AND KEEP DOWNLOADING EPISODES 1 - 7::\n\n::WE WILL BE BACK, STRONGER THAN EVER WITH DARKLIGHT PODCAST EPISODE 8 DROPPING ON 1/07/10::\n\nFULL SPECTRUM DRUM 'N' BASS AND ELECTRONIC MUSIC FROM BRIGHTON and HOVE! \n\nThe Darklight Podcast - produced/hosted/mixed by Unison (J:immy Unison + OD)\n\nNothing but Fresh, high quality electronic music available through iTunes or direct download. \n\nClick the 'website' link above and to the right of this text to be taken to the facebook darklight podcast group! \n\nYOU DO NOT NEED TO BE A FACEBOOK MEMBER TO SEE THE INFORMATION AT THE ABOVE LINK! \n\nYou can also check us out on SoundCloud - http://www.soundcloud.com/darklightpodcast - here you can stream / download all the latest episodes of the podcast. \n\nIf you are a producer from the Brighton and Hove area you can also upload your music using the 'dropbox' - we will then include it in future podcasts - give as much info as you can so we can promote your music!	https://darklightpodcast.jellycast.com/files/podcast300x300.jpg
1563	http://darmstadt-aktuell.podspot.de/rss	Darmstadt aktuell	Darmstädter Tonband- und Stereofreunde	Hörzeitung für Blinde und stark Sehbehinderte aus Darmstadt und Umgebung. Herausgegeben vom Magistrat der Wissenschaftsstadt Darmstadt. Redaktionell gestaltet und produziert von den Darmstädter Tonband- und Stereofreunden.	\N
1564	http://darowski.com/btb/btb.xml	Beyond the Box Score Podcast	Beyond the Box Score (adarowski@gmail.com)	The official podcast of Beyond the Box Score, hosted by Blake Murphy.	http://darowski.com/btb/btb-logo.png
1565	http://darren-d.podomatic.com/rss2.xml	Darren D's Podcast	Darren D	DJing in clubs since the age of 16, Darren has spent the last 6 years playing at various nightspots on the south coast and appearing in line-ups alongside DJ’s such as Derrick Carter, Raymundo Rodriguez and Joey Youngman. Now a resident for underground house outfit iNDiGO, he is still taking his mix of deep and jacking Chicago house to clubs such as Mud Club (Bognor), Drift Bar (Southsea) and Tiger Tiger (Portsmouth) as well as appearances at Brighton’s OM Bar and on Upfrontdance.net radio. \n\nAfter working in all aspects of the industry from selling records to promoting and running his own nights, Darren has built up a world of knowledge that proves invaluable when in front of an audience.\n\nWith appearances across the south coast already, 2010 has already proved to be another good year for the 22 year old self proclaimed house purist.	https://assets.podomatic.net/ts/5e/57/98/darren-d/1400x1400_2807151.jpg
1566	http://darren1576.podOmatic.com/rss2.xml	Darren C's Podcast	Darren C		https://darren1576.podomatic.com/images/default/podcast-2-1400.png
1567	http://darrenmain.libsyn.com/rss	Living Yoga with Darren Main	Darren Main	Hear interviews with leading voices in the spiritual, holistic health and Social Activism.  Hosted by author and yoga teacher Darren Main.	https://ssl-static.libsyn.com/p/assets/d/7/4/0/d7409020fe85f4f7/2.png
1569	http://darrentyler.podOmatic.com/rss2.xml	Conduit Church Teaching Podcast	Darren Tyler	Welcome to the Conduit Church Teaching Podcast. We teach the scriptures, chapter by chapter and verse by verse. We believe that the Word will do what God promises. When we go through the Bible, the Bible goes through us. It’s not an academic exercise. It’s an encounter with a supernatural God through the pages of this supernatural communication He has given to us. For more information visit: conduitchurch.com	https://assets.podomatic.net/ts/b5/3c/ba/darrentyler/pro/3000x3000_14900273.jpg
1570	http://darryl-canty.squarespace.com/messages?format=rss	Arbor Bridge Church	Darryl Canty	Each week during our Worship Experience Darryl will bridge the gap between people and Jesus.	https://images.squarespace-cdn.com/content/50ec47efe4b04b8b89342005/1452050418405-PX2S8NEOFZLO5SGYJ2HB/ARBORBRIDGE-podcast+logo1400.jpg?content-type=image%2Fjpeg
1578	http://data.radiodanz.com/addiction/podcast.xml	DJ Armando's Addiction	DJ Armando	Join DJ Armando for his weekly trip into the newest and best dance music.  The same show heard exclusively weekdays on Radio Danz (www.radiodanz.com) is now available as a podcast!	http://server1.radiodanz.com/addiction/armando.jpg
1579	http://dataclonelabs.com/security_talkworkshop/datasecurity.xml	The CyberJungle	Ira Victor	The CyberJungle is the nation's first news talk show on security, privacy and the law.	http://thecyberjungle.com/images/TCJsplash2.jpg
1580	http://datamax.podomatic.com/rss2.xml	DATA MAX	datamax	DaTaMax - Mercredi 20H - 22H sur MAX FM et sur Deejay Radio(94.5 FM Grenoble en France)www.datamax.fr	https://assets.podomatic.net/ts/4a/4f/e0/datamax/1400x1400_12865267.jpg
1581	http://datastori.es/feed/podcast/	Data Stories	Enrico Bertini and Moritz Stefaner	Enrico Bertini and Moritz Stefaner discuss the latest developments in data analytics, visualization and related topics.	http://datastori.es/wp-content/uploads/2017/12/ds-1400-facelift.png
1582	http://datdamndirty.podomatic.com/rss2.xml	DjDirty.US	Dj Dirty	Radio NOT for the faint of heart. We play what we want and sat what we want. Mix-shows, Interviews, News and more. visit our page http://djdirty.us LET'S GO!	https://assets.podomatic.net/ts/6b/73/c1/datdamndirty/0x0_8451519.gif
1584	http://dattrax.podOmatic.com/rss2.xml	house music by dattrax	dattrax	dattrax is Jim and Dat, Best Friends for over two decades, DJ Duo and fanatic House Fiends!  From Toronto, Ontario, Canada!\n\nWe only listen to, play house music or anything that would sound good mixed with it.\n\nCome enjoy our passion and please comment after listening.  You are the inspiration.\n\nfrom DJ Bio: "...I was in love with house and DJing when I realised that it wasn't music in the sense of Mozart, but a form of self expression- participating in making a musical collage. Like a musical cut and paste. You get to pick your favourite songs, how fast or slow, or how long you want to play it, which part of the song you want to highlight, whether you want to cut it up or layer it, whether you want the feel to be smooth or charging, whether you want... The combinations are endless w/ house music, and that much fun!"\n\nJust so that you know that we are giving you our best as far as time, energy and love...\n\nWe only buy 8-12 vinyl records for every 100 records we listen to.  Jim & I have probably bought over 60crates of house over the years- that's over 6000 records!  We only buy 15-35 tracks for every 1000-2500 mp3's that we listen to. Sometimes less. We are beat junkies and buy every month!!\n \nFinally, we only end up playing 80% (or less) of what we buy because it has to give us goosebumps, make us say 'WOW' or make us put our fists in the air when listening to a track and sometimes after you buy, you decide that you don't like the track as much.\n\nHow do we describe our sound?\nAlways Fun, Tech- Fused, Funky- Foot Stompin', Carved Deep and Woven & Laced with Sweet Smooth Hands in the Air Vocals... Strictly House Music- always dattrax\n\nFOR FULL DJ BIO PLEASE SCROLL ALL THE WAY DOWN TO THE MIX CALLED "BASIC CAUSE" BECAUSE THE BIO STARTS THERE.\n\nFOR BOOKINGS, ADDITIONAL COMMENTS OR QUESTIONS PLEASE EMAIL US: dattrax@gmail.com	https://assets.podomatic.net/ts/d4/3e/0d/dattrax/pro/3000x3000-1536x1536+0+424_2438992.jpg
1585	http://dave.podspot.de/rss	SCHLIMMER geht's nimmer!	David Unger	Trailer zum kuenftigen Low-Budget-Spielfilm\r\n(Independent-Film)\r\n\r\nD/Oe - Komoedie - 90 min\r\nDrehbeginn: 2006\r\nVeroeffentlichung: 2007	\N
1586	http://davedecibel.podomatic.com/rss2.xml	the Decicast	Dave Decibel	Based out of Albuquerque, New Mexico - Its Dave Decibel!	https://assets.podomatic.net/ts/8f/c7/ac/davedecibel/0x0-637x637+56+0_6772705.jpg
1588	http://davefogg.podomatic.com/rss2.xml	Dave Fogg	Dave Fogg		https://assets.podomatic.net/ts/72/9b/24/dfogg/3000x3000_10585747.jpg
1589	http://daveinthecity.podbean.com/feed/	Dave in the City out West (DITCOW)	Dave Medina	Dave in the City & Kevin on the Cape talk sports & entertainment in an uncensored, freeform show. Guests cover the biggest games in MLB, NFL, NBA, & NCAA.  Coverage of:  Lakers, Dodgers, Chargers, 49ers, Giants, Seahawks, UCLA, USC, Oregon, Washington, Arizona, Kings, Ducks, Sharks, Suns, and more.	https://pbcdn1.podbean.com/imglogo/image-logo/147393/DITCOW_Word_Logo.png
1590	http://daverabbit.podOmatic.com/rss2.xml	Dave Rabbit	Dave Rabbit	The World Is Listening To\n\nDAVE RABBIT\n\n\n\nAre You?\n\n”Dave Rabbit”, the “Godfather Of Pirate Radio”, welcomes you to "The Rabbit Zone". So Fasten Your Seat Belts, bring your seats and tray tables to their Fully Upright Position, then bend over and Kiss Your Ass Goodbye, because the “Dave Rabbit”  &  “Radio First Termer”  Pirate Radio Experience is an Extremely Dangerous & Bumpy Ride! Everything Here Is FREE To Enjoy & Share!\n\nDAVE RABBIT\n\nLOVES\n\n\n\nJESSICA RABBIT\n\nMilitary EntertainmentNetwork\n\nIn 2006, Dave Rabbit founded the Military Entertainment Network as a vehicle for Podcasters from around the world to join his cause to bring FREE  quality entertainment to the men and women around the world in combat zones for the United States and her Allies. To date, over 1,000 Podcasters from almost every country in the world have joined Dave Rabbit in this cause.\n\n\n\n”We Entertain The Troops”\n\n\n\n A Tribute To My MentorBOB HOPE\n\n An NBC Tribute To TheBOB HOPECHRISTMAS SHOWS\n\n\n\n\n\n\n\n\n\n\n\nDAVE RABBIT HISTORY\n\nRadio First Termer was a Pirate Radio Station which broadcasted nightly from January 1, 1971 to January 21, 1971 in Saigon during the Vietnam War. Radio First Termer was hosted by on-air personality "Dave Rabbit", an anonymous United States Air Force sergeant. The two other members of the crew were known as "Pete Sadler" and "Nguyen".\n\nDave Rabbit - 1971\n\n\n\nDave Rabbit - Today\n\n\n\n\n\n\n\n\n\n\n\n”Dave Rabbit”, who is greatly considered as the Godfather of Pirate Radio and the first true “Shock Jock”, began his radio career in Vietnam working as a studio engineer for Radio Phan Rang. After three tours in Vietnam, "Dave Rabbit" and his friends launched Radio First Termer from a secret studio in a backroom of a Saigon brothel. The make-shift studio walls were lined with mattresses to deaden the sounds emanating from the brothel. The station broadcasted for a total of 63 hours over 21 nights (between January 1, 1971 to January 21, 1971). “Dave Rabbit” later admitted in an interview, that he was forced to stop broadcasting because he was fearful that his friends, who were protecting him and the show, were in imminent danger of getting in trouble by his base commander, who hated his show and suspected that someone was protecting him.\n\n\n\t\nThe purpose of Radio First Termer, according to “Dave Rabbit”, was to "bring rock and roll to the troops on the front lines." The station played "hard acid rock" such as Steppenwolf, Bloodrock, Three Dog Night, Led Zeppelin, Sugarloaf, the James Gang, and Iron Butterfly, bands which were popular among the troops but largely ignored by the American Forces Vietnam Network (AFVN). The music was mixed with antiwar commentary as well as skits poking fun at the U.S. Military, Lyndon B. Johnson, Richard M. Nixon, the Base Commander, just to name a few. Raunchy sex and drug oriented jokes were always a tremendous part of the nightly shows. “Dave Rabbit's” show also included a number of bits including “Tooth Picks In The Toilet”, the “Dave Rabbit Official Sweatshirt” and reading GI comments off the latrine walls across Vietnam.\n\n\n\nAlthough the frequency was always announced as FM69, “Dave Rabbit” has said in several interviews, in reality the show was broadcast over numerous frequencies. In addition to 69 MHz FM as selected by “Dave Rabbit”, the Radio Relay troops across Vietnam also broadcasted Radio First Termer over other frequencies, including 690 AM.\n\n\n\nIn 1995 Will Snyder first posted sound clips from a Radio First Termer broadcast on the internet renewing interest in “Dave Rabbit” and Radio First Termer. In February 2006, after finding out that the surviving show was posted on the internet, "Dave Rabbit" came forward and told his story to several main stream media personalities including Corey Deitz with About Radio. Dave also did an interview with Director David Zeiger for a bonus feature on the DVD release of Sir! No Sir!, who had u(continued)	https://assets.podomatic.net/ts/97/5b/31/daverabbit/3000x3000_1457442.jpg
1592	http://daveymacsportsprogram.libsyn.com/rss	Davey Mac Sports Program	Dave Mcdonald	"East Side" Dave McDonald (of Sirius XM Satellite Radio) and friends dominate the airwaves with this hugely popular show that discusses sports, movies, and pop culture with passion and irreverence! You've NEVER heard a sports show like this before!	https://ssl-static.libsyn.com/p/assets/f/f/5/d/ff5d21b7045339bf/DMSP_Beard.jpg
1595	http://davidfeldmanshow.libsyn.com/rss	David Feldman Show	David Feldman	Some of America's best comedians, writers and performers come together for conversation.	https://ssl-static.libsyn.com/p/assets/6/1/b/4/61b49d4ce49c8a3b/episode-g.jpg
1596	http://davidgore.podomatic.com/rss2.xml	Manly Village Talks	David Gore	Join us in our weekly madness of allowing the ancient text to dissect us and expose our innards... no really, its fun!	https://assets.podomatic.net/ts/cd/f3/e3/davidgore/3000x3000_9587317.jpg
1599	http://davidmenestres.com/feed/podcast/	Tone Science	dmenestres@gmail.com (Tone Science)	Tone Science is a free form radio show exploring the wide world of music and sound, airing weekly on Sunday nights on listener funded, non-commercial taintradio.org.	http://davidmenestres.com/wp-content/uploads/2019/05/tone-science.jpg
1600	http://davidmgreen.com/files/rss/thegoodshowpod.xml	The Good Show	David M. Green & Anthony McCormack	From fabulous Studio Pleasant in the heart of Melbourne, The Good Show is an audio feast of sketch comedy and radio satire.	http://davidmgreen.com/files/Images/The_Good_Show_Logo_2_1400x1400.jpg
1601	http://davidnagy.web.elte.hu/dgykozmofizika.rss	Kozmofizika	Nagy Dávid	Dávid Gyula előadásai a Polaris Csillagvizsgálóban. A Magyar Csillagászati Egyesület felvételei.	http://davidnagy.web.elte.hu/dgykozmofizika.png
1602	http://davidnagy.web.elte.hu/dgyrelativitas.rss	Relativitáselmélet	Nagy Dávid	Dávid Gyula előadásai a Polaris Csillagvizsgálóban. A Magyar Csillagászati Egyesület felvételei.	http://davidnagy.web.elte.hu/dgykozmofizika.png
1603	http://davidnagy.web.elte.hu/dgyrelativitasaudio.rss	Relativitáselmélet (Audio)	Nagy Dávid	Dávid Gyula előadásai a Polaris Csillagvizsgálóban. A Magyar Csillagászati Egyesület felvételei. (Csak hanganyag, van video változat is.)	http://davidnagy.web.elte.hu/dgykozmofizika.png
1605	http://davincicode.podOmatic.com/rss2.xml	Da Vinci Code Domains and Podcasting	davincicode	Commentary on the Explosion of Podcasting and our offer regarding The Da Vinci Code.	https://davincicode.podomatic.com/images/default/podcast-3-1400.png
1606	http://davinciwakes.podomatic.com/rss2.xml	da Vinci's Waking Dream	Will Norman	Da Vinci's Waking Dream offers tips and advice for gay entertainment professionals, and interviews with gay writers, musicians, artists, and new/traditional media professionals to help you achieve your dreams.	https://assets.podomatic.net/ts/92/0d/b1/behindthescenes2003/3000x3000_3338996.jpg
1608	http://davinhsiao.podomatic.com/rss2.xml	Yatsu Music Podcast	Davin Hsiao	Yatsu (bass control ,Taipei) \nbegin to be in touch with electronic music in 2002. Fascinateed,as the electronic music effects and beats variety. 2007 from his friend to bring him into the mixing skills and by his teacher J-Six to teached him know about all music products in electronic music. 2009 his first time djing shows on stage that public. His favorite gerne of music is progressive house,trance.\n\nfor contact:\ninfo@bass-control.com\nyatsu@bass-control.com\n\nbass control \nis the production and DJ team founded by J-Six since 2009. J-Six is the pioneer event producer for past 10 years in Taiwan, and work with the LOOP production closely. He began to DJ since 1993, and the past residency clubs included Spin, Roxy, Room 18, 2nd Floor. bass control introduces new talents chosen from J-Six, Yatsu, DJ Feo and FDaniel.\n\nPast date:\n2010\nEller van Buuren with B.E.N. @ XAGA, Taichung\nbass control "2F WHITE Prologue" Special guest: F Daniel @ XAGA, Taichung\nbass control "with PROJECTIONS" Visual: Dominik (ASOS), Fun Dee-Lite @ Luxy, Taipei\n\n2009\nbass control @ Luxy, Taipei\nbass control "2F WHITE Prologue" ft. Justin & Sophia(JS) @ XAGA, Taichung\nbass control "R2-J6" @ XAGA, Taichung\nbass control "neo-fluor" ft. Meighan Nealon @ XAGA, Taichung\nbass control x FAMFATAL "Happy bF" @ XAGA, Taichung\nbass control x FAMFATAL "Happy bF" @ Luxy, Taipei	https://assets.podomatic.net/ts/60/1d/0d/yatsu65199/3000x3000_5002646.jpg
1872	http://disney.go.com/disneyvideos/podcasts/disney_dvd_news.xml	Disney DVD News	Disney Online	Find out what Disney has coming out on DVD.	http://disney.go.com/disneyvideos/podcasts/disney_dvd_news.jpg
1609	http://dawgcast.libsyn.com/rss	DawgCast Podcast	Derek Leonard	Broadcasting from deep under Sanford Stadium. We bring you all the news from the Georgia Bulldog Football Program. Practice notes, pre-game, post-game, tailgate reports, recruiting and spring ball. This show is by fans for fans with stuff you'll never hear in the mainstream. If you want the real deal, this is it.	http://static.libsyn.com/p/assets/1/6/9/4/169421928f6dab2d/Dawgcast_Logo_Square_v2.jpg
1610	http://dawhelp.com/rss/protools/dawhelp-ProTools.xml	dawHelp.com - Pro Tools	Adam Olson	This netcast offers tips on using Digidesign's Pro Tools.	http://www.dawhelp.com/rss/protools/Images/ProTools.jpg
1611	http://dawnfarm.libsyn.com/rss	Dawn Farm Addiction and Recovery Education Series	Dawn Farm	The Dawn Farm Education Series is a FREE, annual workshop series developed to provide accurate, helpful, hopeful, practical, current information about chemical dependency, recovery, family and related issues; and to dispel the myths, misinformation, secrecy, shame and stigma that prevent chemically dependent individuals and their families from getting help and getting well.  The 2012/2013 series marks the TWENTY-SECOND year of Dawn Farm providing this educational resource for our community!	https://ssl-static.libsyn.com/p/assets/6/f/5/9/6f5925654399aaf5/DF_logo_greyscale.jpg
1612	http://day1.org/weekly_broadcast.rss	Day1 Weekly Program	pwallace@day1.org (Day1.org)	Each week the Day1 program, hosted by Peter Wallace, presents an inspiring message from one of America's most compelling preachers representing the mainline Protestant churches. The interview segments inform you about the speaker and the sermon Scripture text, and share ways you can respond to the message personally in your faith and life.	https://day1.org/images/item-photo/day1org-podcast.jpg
1615	http://dayvedean.jellycast.com/podcast/feed/24	Dayve Dean - free downloads - demos, covers and live	Dayve Dean	Free downloads from singer/songwriter Dayve Dean.\n\nRegular updates including demo songs, studio recordings, live recordings and alternative mixes.  Find out more and join the mailing list at <a href="http://www.dayve.co.uk">dayve.co.uk</a>, <a href="http://facebook.com/dayvedean">facebook.com/dayvedean</a> or <a href="http://www.myspace.com/dayvedean">myspace.com/dayvedean</a>.	https://dayvedean.jellycast.com/files/downloadoftheweek.jpg
1616	http://dazboy.podOmatic.com/rss2.xml	Dazboy's podcast	Dazboy		https://assets.podomatic.net/ts/a7/39/0e/dazboy/3000x3000_3631595.jpg
1617	http://dazdillinja.podOmatic.com/rss2.xml	dj dAz presents: soul, rare groove, hip hop and ting'	dj daz	20 years of experience as a dj/promoter/producer and all around horticulturalist on digging for beats and planting the musical seeds of rhythms and sounds in the Los Angeles music scene, dj dAz brings you the best in soul, reggae, hip hop, jazz, funk, deep house, and dance classics available for free (BUT DONATIONS ARE DEFINITELY APPRECIATED). dig it!!! Oh... And you can find me online @deejaydaz for IG & Twitter. Cheers!	https://assets.podomatic.net/ts/95/83/33/dazdillinja/pro/3000x3000_1979984.jpg
1618	http://dbcmedia.org/podcasts/love_song_podcast.xml	DENTON BIBLE CHURCH > Love Song > The Song of Solomon	Denton Bible Church	It should come as no surprise to us that God has much to say about romantic love. In the Song of Solomon God has given us a divine manual on romantic relationships, taking us from the initial attraction between a couple through courtship, deepening intimacy and marriage. This careful study of Solomon’s Love Song, always insightful and at times explicit, can guide you toward the emotionally and sexually satisfying marriage that God desires for you.	http://dbcmedia.org/podcasts/dbc_love_song.jpg
1620	http://dblockshow.podomatic.com/rss2.xml	D's Block	Dejacks	The Block belongs to Dejacks...D's Block. An extension of my passion for music, cars & life. A place to escape and listen to the expressions  of my life.	https://assets.podomatic.net/ts/32/ad/cb/dblockshow/3000x3000_7783178.jpg
1621	http://dbmedia.s3.amazonaws.com/podcast/rss.xml	Desert Breeze Community Church Podcast	Desert Breeze Community Church	Desert Breeze Community Church exists to provide a place where unchurched people can become fully devoted followers of Jesus Christ.	http://dbmedia.s3.amazonaws.com/podcast/dbcc_podcast_logo.jpg
1623	http://dbp.podbean.com/feed/	DualBoot			https://pbcdn1.podbean.com/imglogo/image-logo/47025/logo.jpg
1625	http://dcbrown.jellycast.com/podcast/feed/2	Deep House Harmonic Sessions Podcast	Danny Coffill-Brown	The very Best Selection in Deep house Mixed Harmonically Each Month By DC Brown \nFeaturing His Unreleased and Fourth Coming Tracks. contact DC Brown on Admin@dialadealer.co.uk or @dcbrowndeep on twitter  if you would like to do a guest Mix only rule is that it is Deep and mixed Harmonically All so you Contact  Me on deepcast@dcbrown.co or the official deep harmonic sessions podcast twitter @deepcast2013 if for any thing related to my Music or this Podcast. New Episodes out on The 16th of Every Month for general podcast en	https://dcbrown.jellycast.com/files/harmonic%20sessions%20eddited%20itunes%201400.jpg
1626	http://dccomicsnews.com/category/podcast/feed/	DCN Podcast – DC Comics News	\N	DC Comics News: Welcome to the #1 source for DC Comics!	\N
1630	http://dcsportspulse.podOmatic.com/rss2.xml	DC Sports Pulsecast	Derrick Roos	Covering the Redskins, Wizards, Capitals, Nationals, Orioles, Capitals, Terps, and more...  Make sure to check out www.dcsportspulse.com for local sports news and commentary.	https://assets.podomatic.net/ts/07/25/56/dcsportspulse/1400x1400_1111798.jpg
1631	http://dcuniverseclub.podomatic.com/rss2.xml	DC Universe Club Podcast	DCUniverseClub	DC Universe Club รายการ Podcast คุยกันเรื่อง Superhero,Comics Book ต่างๆไม่จำเป็นต้องเป็น DC อย่างเดียว Marvel เราก็คุยได้ จัดรายการโดยผู้เข้าแข่งขัน รายการ แฟนพันธุ์แท้ แบทแมน และทีมงาน www.comics66.com	https://assets.podomatic.net/ts/69/74/25/podcast55218/3000x3000_7079476.jpg
1634	http://dcwandercast.podomatic.com/rss2.xml	DC Wandercast	jbrint	Welcome to DC Wandercast, a podcast dedicated to walking tours of different Washington DC neighborhoods. Check out dcwandercast.tumblr.com for more! (Podcast art from Mr. T in DC on Flickr)	https://assets.podomatic.net/ts/54/cb/38/dcwandercast/3000x3000_7320734.gif
1635	http://dcwva.libsyn.com/rss	Archive	The DCW Variety Hour	Australia's only uncensored show focusing on the world of Pro Wrestling and Mixed Martial Arts.\nThe show features the opinions of George Demirov, Criss Fresh, Sebastian Walker and Michael Tye while Paul Jones attempts to contain the chaos.\nCovering all the news and rumours from Australia and abroad, The DCW Variety Hour also features interviews with some of the biggest stars.\nPrevious guests include Chris Jericho, Ric Flair, Jeff Jarrett, The Miz, Jimmy Hart and Lanny Poffo.\nNew shows will be posted weekly	https://ssl-static.libsyn.com/p/assets/c/e/c/7/cec74f5a804d1212/soapy.png
1701	http://defensores.podOmatic.com/rss2.xml	Defensores Podcast	Defensores de la Fe	Defensa de la Fe Bíblica Apostólica. Información sobre apologética, religiones, sectas y más.	https://defensores.podomatic.com/images/default/podcast-4-1400.png
1636	http://ddirtyshow.podOmatic.com/rss2.xml	Da Doo-Dirty Show Podcast	DJ Baker	Da Doo-Dirty Show is one of the shows that has become a staple in the community, while being the only show to be delivered 5 days a week for 2 hours a day, bringing the best in Hip-Hop and R&B into homes across the globe now LIVE via http://alldigitalradio.com and rebroadcasted via QNATION.FM from 4 pm to 6 pm. Da Doo-Dirty Show also is one of the only sources to hear most LGBT hip-hop and R&B artist mixed in with underground, independent and popular music of today, garnishing the tag line “Blazing The Best Mixture Of Hip-Hop/R&B, and The Best Talk In The Land.	https://ddirtyshow.podomatic.com/images/default/podcast-3-1400.png
1637	http://ddrezddrez.podomatic.com/rss2.xml	WolfBane MusicCast	**ew *a*i*o*e	Our Bands Music, sorry... no Lyrics	https://assets.podomatic.net/ts/88/b6/00/ddrezddrez/1400x1400_603325.jpg
1638	http://dds02.common.foxbd-live.com/u/ContentServer/MGM/Static/Common/Podcast/XML/Bond_50th_Podcast_RSS_Feed.xml	FIFTY YEARS OF JAMES BOND: Behind-the-Scenes	MGM	In celebration of 50 years of Bond, watch 7 unique behind-the scenes featurettes in this podcast! All films are now available for digital download!	http://dds02.common.foxbd-live.com/u/ContentServer/MGM/Static/Common/Podcast/Images/BONDAT50_1400x1400.jpg
1639	http://ddt.podOmatic.com/rss2.xml	DDT - Diamoci del Tu	ddt	Varietà radiofonico settimanale basato sull'improvvisazione e sul divertimento. Intrattenimento giovane e dinamico.\ne-mail: diamocideltu@rmf.it	https://assets.podomatic.net/ts/aa/37/a3/ddt/1400x1400_602905.jpg
1640	http://de-pod-op.podomatic.com/rss2.xml	De Pod Op	De Pod Op	Podcasting, what happened? In 2005 was het de next best thing, maar de laatste jaren is het verdacht rustig rond het medium. Tijd voor een rondvraag: zit er nog toekomst in podcasting? En zo ja: welke?	https://assets.podomatic.net/ts/4f/ad/cb/63043/1400x1400_8245663.png
1649	http://deadbedouins.podbean.com/feed/	The Dead Bedouins Podcast	The Dead Bedouins	Group of friends talk openly about dark, funny, controversial, and taboo topics, improvise sketch comedy, and make each other laugh.	https://pbcdn1.podbean.com/imglogo/image-logo/605852/deadbedouins_lg.jpg
1651	http://deadhorsefightsback.com/rss	Dead Horse Fights Back	\N	Offending People Across The Globe Since 2012!	\N
1653	http://deadlydragonsoundsystem.podomatic.com/rss2.xml	Deadly Dragon Sound's Reggaematic Podcast	DEADLY DRAGON SOUND	Deadly Dragon Sound has spent 20+ years collecting, selecting and selling some of best and rarest Jamaican vinyl and we use all that experience providing you with podcasts that showcase our unique sensibilities in regards to the full history of Jamaican music from Ska to rocksteady to reggae to roots to rubAdub to digital to dancehall and beyond! Nuff Respect and always remember to check www.deadlydragonsound.com	https://assets.podomatic.net/ts/b6/fa/33/deadlydragonsoundsystem/3000x3000_2548944.jpg
1655	http://deadthyme.libsyn.com/rss	deadthyme radio show	deadthyme	[deadthyme] is a two and a half hour weekly underground modern counter-culture radio show that is broadcast on non-commercial KPFT 90.1 FM in Houston, TX (so there's no commercials or interruptions). Modern counter-culture music can be defined many different ways, but for this show it's defined as punk, goth, industrial, and all the subgenres therein (death rock, hardcore, industrial noise, grindcore, darkwave, crust, oi!, e.b.m., d-beat, noizecore, gothic metal, power violence, straight-edge, horror punk, experimental, etc.) as well as other forms of offbeat music that slip between the cracks (such as Negativland, Swans, Chrome, Big Black, etc.) and even a little extreme metal and doom/ funeral doom on occasion.	https://ssl-static.libsyn.com/p/assets/2/f/4/a/2f4ad82ef98b9901/300x300.jpg
1656	http://deandelray.libsyn.com/rss	Dean Delray's LET THERE BE TALK	Dean Delray	Dean Delray's "Let There Be Talk." This original podcast is a unique blend of rock and comedy talk with some of the biggest names in music, comedy and entertainment.	https://ssl-static.libsyn.com/p/assets/1/4/f/b/14fbc4165e6c5bb8/4D6B4965-370B-49D4-9370-A18E56C07D63.jpeg
1658	http://deanjay.podOmatic.com/rss2.xml	DeanJay Deep and Soulful House Mixes	DeanJay	Deep and Soulful House Mixes from DeanJay Resident and Promoter the upcoming Soul:Fly Brand, DJ on DV.FM and Resident at SaveOurSoul.es (Marbella). The best music mixed and blended with love. Also find 60+ mixes at www.waxdj.com/djs/2878	https://deanjay.podomatic.com/images/default/podcast-1-3000.png
1662	http://deathtechno.podomatic.com/rss2.xml	Death Techno	Death Techno /// Podcast Mix Series	Death Techno is a bi-weekly mix show ran by Jack! Who? serving up Exclusive Techno sets from around the world from hand picked underground DJ talent to established artists. Please check out our site http://deathtechno.com for more info...\n\nWe are premiere on soe.fm in Germany then available for streaming and download shortly after via SoundCloud that now has over 4,900 Followers.\n\nSome guests featured so far are... Alex Dolby, Erphun, Hefty, Heron, Joachim Spieth, L.A.W, Mike Wall, Miss Sunshine, Niereich, Re:Axis, Reggy van Oers, Ricardo Garduno, Rocco Caine, Vegim, Wave Form and many more...	https://assets.podomatic.net/ts/07/dc/43/deathtechno/3000x3000_14332321.jpg
1663	http://debatablepod.libsyn.com/rss	The Debatable Podcast	Gregory Sahadachny	A free-form discussion about people's passions, media and life.	https://d3t3ozftmdmh3i.cloudfront.net/production/podcast_uploaded/2095864/2095864-1564682816522-88797aa7cff98.jpg
1664	http://decoderring.libsyn.com/rss	Decoder Ring Theatre	Gregg Taylor	Decoder Ring Theatre presents new stories and characters inspired by the classic broadcasts of the Golden Age of Radio. The crimebusting exploits of The Red Panda - Canada's Greatest Superhero! The mystery of that hardest-boiled of detectives, Black Jack Justice... all this and more in full-length, full-cast recordings.	https://ssl-static.libsyn.com/p/assets/0/1/a/b/01ab06341934c3a1/Logo.png
1666	http://deconstructingdinner.libsyn.com/rss	Deconstructing Dinner	Deconstructing Dinner	Deconstructing Dinner is a podcast/radio show that broadcast between 2006 through 2011 with a brief return of a handful of episodes in 2014. Almost 200 episodes are available on topics ranging from corporate consolidation, animal welfare, urban food production and the local and good food movements. With host Jon Steinman.	https://ssl-static.libsyn.com/p/assets/2/0/4/f/204f7597c73803d1/DD_logo_teal.jpg
1668	http://decormie2551.sermon.tv/rss/main	Dakota Community Church	Dan Cormie	Welcome to the media ministry of Dakota Community Church.	http://storage.sermon.net/99b04d2274f555ae01bcc53b149cd6a1/5f9561af-0-0/content/media/common/artwork/SN-default-1400x1400.png
1669	http://decoy.podomatic.com/rss2.xml	Dj Decoy podcast	DJ Decoy	Dj Decoy The Hype of New York @DJDECOY	https://assets.podomatic.net/ts/1c/20/32/decoy/3000x3000_14479741.jpg
1673	http://deejarch.podOmatic.com/rss2.xml	DJ ARCH Soulful House Sessions	DJ ARCH	Quality Deep Soulful House podcasts available for free download. Enjoy the mixes and please share. The DJ ARCH MOBILE APP is available for free download as well at http://bit.ly/djarchapp on all major platforms.	https://assets.podomatic.net/ts/5a/6d/40/deejarch/3000x3000_7743388.jpg
1674	http://deejay-jey.backdoorpodcasts.com/index.xml	LATINO STAND UP OFFICIAL PODCAST by DJ JEY	Dj Jey	LO MEJOR DEL REGGAETON Y DEL MOVIMIENTO LATINO URBANO MIX by dj jey	http://deejay-jey.backdoorpodcasts.com/uploads/items/deejay-jey/latino-stand-up-official-podcast-by-dj-jey.jpg
1675	http://deejayad.podomatic.com/rss2.xml	Deejay AD's Podcast	Deejay AD		https://assets.podomatic.net/ts/68/7a/3e/deejayad/3000x3000_3272378.jpg
1676	http://deejayadfu.podomatic.com/rss2.xml	Deejay AD's Podcast	Deejay AD		https://deejayadfu.podomatic.com/images/default/podcast-4-1400.png
1677	http://deejayag.podOmatic.com/rss2.xml	Agressive House Podcast by AG	Deejay AG	Agressive House Podcast ! Only the best track from Miami to Ibiza ! A new episode every month on free download ! Available on iTunes and Soundcloud ! Selected and Mixed by AG\n\nFollow me on Twitter : http://twitter.com/deejay_ag\n\nFacebook : http://www.facebook.com/Deejay.ag\n\nsoundcloud : http://soundcloud.com/deejayag	https://assets.podomatic.net/ts/8b/40/a5/deejayag/0x0_8073173.jpg
1678	http://deejayfreek.podOmatic.com/rss2.xml	Mr F R E E K's Podcast	Deejay Freek		https://assets.podomatic.net/ts/77/e9/ce/deejayfreek/1400x1400_1856966.jpg
1679	http://deejayjj20.podomatic.com/rss2.xml	Social Legacy (Mile High Sessions)	Social Legacy	Social Legacy, a rather new comers to the Production scene is comprised of two seasoned DJs from Denver, CO. DJ 40watt (Eric Valles) and JayJay (Jason Alvarez) have been around EDM for lengthy period of time. They have know come together to create Social Legacy and bring together their knowledge and sounds of Electro, Trance and Dubstep. Since picking up these genres 40watt has played a number of massive events in the Denver area and soon began to produce Dubstep of his own! Yet none of his production were ever leaked to the public via social media they were real rounded and played in a number of his sets! At the age of 20 JayJay has Shared the stage with TOP HEADLINERS of the WORLD such as, JELO, VERDUGO BROTHERS, SIMPLY JEFF ,HATIRAS, WILL BAILEY, BRYAN COX, COSMIC GATE, DJ RAP(#1's Female DJ) DJ VENOM, UFO, STONEFACE & TERMINAL, SEAN TYAS, TRITONAL, MAT ZO, SPACE ROCKERZ, THE ELEMENTALS, PAUL ANTHONY, ZXX, SOUTHPAW . The two have joined forces now and you can expect nothing short of epic club bangers from the duo know as SOCIAL LEGACY!\n\nBooking information\nSociallegacyradio@gmail.com\nwww.facebook.com/sociallegacy\nhttp://twitter.com/#!/social_legacy\nhttp://soundcloud.com/social_legacy\nImmortal Beatz	https://assets.podomatic.net/ts/a4/24/11/deejayjj20/3000x3000_8360204.jpg
1680	http://deejaykifiinf.podomatic.com/rss2.xml	Dj KiFinF	Dj KiFinF		https://assets.podomatic.net/ts/cf/7d/b7/kifinf-83/3000x3000_6690101.jpg
1681	http://deejayl.podomatic.com/rss2.xml	Deejay L's Podcast	Deejay L		https://deejayl.podomatic.com/images/default/podcast-3-3000.png
1682	http://deejaymarlon.podomatic.com/rss2.xml	DJ MARLON Radioshow & Travel in the Deep PODCAST	Dj Marlon	Dj Marlon Lira and the music sounds better - the radioshow - podcast - dance disco and house music deep	https://assets.podomatic.net/ts/65/a9/50/info66487/pro/3000x3000_13604695.jpg
1684	http://deejaynd.backdoorpodcasts.com/index.xml	MixShake	Dj ND	Deejay ND vous emmène dans son univers. Jamais 100% hop-hop ni 100% electro, il aime mélanger les deux styles à coups de scratch aiguisés et de phases techniques propres à un champion DMC. En solo ou avec des deejays internationaux, ND lève toujours le niveau d'un cran lorsqu'il diffuse un mix.	http://deejaynd.backdoorpodcasts.com/uploads/items/deejaynd/mixshake.jpg
1685	http://deejayrj.podomatic.com/rss2.xml	Strawberry Funk Series	Deejay Rj	What's Your Flavour? Strawberry Funk Volume 3 Mixed Live by DeeJay RJ	https://assets.podomatic.net/ts/37/55/d1/deejayrj/3000x3000_3949712.jpg
1687	http://deejaystef76418.podomatic.com/rss2.xml	Stefan T's Podcast	Stefan T		https://deejaystef76418.podomatic.com/images/default/podcast-2-3000.png
1688	http://deepaddiction.podomatic.com/rss2.xml	Deep Addiction	Deep  Addiction		https://deepaddiction.podomatic.com/images/default/podcast-1-3000.png
1690	http://deepdrush.podomatic.com/rss2.xml	Deep Drush - 130 BPM Radio Show	Deep Drush	Bienvenue sur mon nouveau podcast ! Vous trouverez ici un mix hebdomadaire de 60 minutes dans un style Electro-House, Progressive House ou encore Minimal au influence de Laidback Luke, sunnery james ryan marciano, dj snake, afro bros, deorro, oliver heldens, martin garrix, Afrojack, Axwell, Steve Angello, Sebastian Ingrosso Above and beyond adam k and soha afrojack benett deadmau5 glenn morisson Ben LB arias arno cost Swedish House Mafia,bingo players,above and beyond,adam k and soha,Daft Punk,Pryda,benett,deadmau5,glenn morisson,Ben LB,arias,arno cost,guetta,garraud,Tiësto,Armin van Buuren,sacha digweed,Pete tong, airbase,alex kenji,manuel de la mare,mlle eva,aly and fila,andrew bennett,mandy,duguid,avicii,axwell,bissen,bobina,booka shade,butch,chris kaeser,chris lake chriss ortega,claes rosen,cosmic gate,d.o.n.s.,dabruck and klein,dada life,dash berlin,dave darell,dave ramone,dim chris,dinka,dirty south,dj antoine,dj dlg,dj shah,dubfire,eddie thoneick,edx,eric prydz,eric smax,fedde le grand,fergie,ferry corsten,filthy rich,first state,funkagenda,gareth emery,gui boratto, hardwell,heatbeat,hi tack,ian carey,inpetto,jaren,jaytech,jean elan,jerome isma-ae,jochen miller,john dahlback,john o callaghan,jonas steur,klaas,a state of trance,anjunabeats,anjunadeep,SPARTAQUE,armada,armind,black hole,coldharbour,euphonic,high contrast,in trance we trust,mau5trap,soundpiercing,spinnin,tiger,toolroom, vandit,laidback,luke,laurent wolf,david amo,julio navas,leon bolier,luetzenkirchen,mango,marcus,schossow,mark knight,markus schulz,martin roth,matt cerf,michael mind,miles dyson,minimal,mondo,moonbeam,myon and shane,nadia ali,oceanlab,oliver huntemann,oliver smith,orjan nilsen,paul miller,pig and dan,player and remady,popof,progressive house,prok and fitch,pryda,r-tem,r.i.o.,robbie rivera,seamus haji,sebastian ingrosso,sebastien leger,signalrunners,spencer and hill,steve angello the prodigy,thomas gold,tiesto,tocadisco,topher jones,trance,tv rock,umek,vandalism,zoo brazil,16 bit lolitas,abel ramos,activeout,afrojack,alaa,albin myers, alenia,alex gomez,asha,atlantis ocean,audible,austin leeds,avicii,banga,bart b more,belocca,beltek,ben preston,bingo players,chris lake,christian smith,christos fourkis,claes rosen,clare canti,dana bergquist,daniel lindeberg,daniel portman,dankann,danny howells,dave kurtis,david tort,dbn,dennis de laat, deux, dezza,dinka,dirty rush,dirty south,disciple,distant fragment,dj daniel cast,dj dark,dj dlg,dj fist,dj geo,dj ralmm,dj reza,don and palm,dons,dumb dan, dylan warren, dyor,eczny, edson pride, edx,fedde le grand,filthyrich,firestone,vitalic,fuel,giorgio giordano,glenn morrison,granau,groove prisoner,hanne lore,hard rock sofa,hardwell,harry brown,harvard bass,helvetic nerds,hideo kobayashi,hy2rogen,incognet,inpetto,james le freak,james zabiela,jason young, jay smith,jaytech,john dalagelis,john selway, jonas sellberg,jose armas,jose nunez,kent and parker,kid massive,kim fai,kleerup,komytea,kosmas epsilon,kris menace,leventina,ludvig holm,luigi lusini,luktro,marc benjamin,marc vedo,marco v,mark knight,martin michaelson,massive,mastiksoul,matteo marini,maurizio gubellini,maxie devine,melting point,mesmerized,michael cassette,michael parsberg,mike,mischa daniels,mobin master, moguai,montero, morgan page, motorcycle, mr da nos,musicialv,my digital enemy,nathan c,niels van gogh,nikitin,niklas gustavsson,offer nissim,office,gossip,olavbasoski,olivermoldan,original,osip,passenger 10,paul damixie,paul keeley,paul van dyk,people,per qx,peter millwood,peter_mcgill, philgood, proff,progressive,quembino,r ulises gonzalez,radiohead,richard colman,riktam,robert m,robert moon,roland clark,romero,ross evans, saeed younan,sandri danny, sandro monte,santiago cortes,schodt,sean marx,sebastian gudding,sebastien leger,second left,sem thomasson,serge devant,sergio fernandez, sevensensis igness with,sezer uysal,shiha,skills,soliquid,sql,stan kolev,stephan luke,sunloverz,swanky tunes,the nycer,theofeel,thomas gold,thomas lan(continued)	https://assets.podomatic.net/ts/5b/20/68/deepdrush02/3000x3000_9231727.jpg
1692	http://deepermotions.podOmatic.com/rss2.xml	Deepermotions Music Monthly Podcast	Deepermotions Music	Welcome to the Deepermotions Music Podcast featuring monthly mixes from Deepermotions A&R Mike Gurrieri & guest DJs from around the globe	https://deepermotions.podomatic.com/images/default/podcast-1-3000.png
1694	http://deepfunkymeb.podOmatic.com/rss2.xml	MARKIEBEEZ HOUSE	MARKIEBEEZ	'WELCOME TO MY HOUSE'\nwww.deepfunkymeb.podomatic.com\n Every month I bring you the Latest & Freshest HOUSE MUSIC from genres HOUSE - TECH HOUSE - FUNKY HOUSE\nEvery month I mix together what I feel are the finest tracks from these genres to create a NEW, FRESH, UPLIFTING, FUNKY but UNDERGROUND HOUSE VIBE.\n Every release has its own Artwork too.\nPLAY LOUD, ENJOY THE TRIP!!\n Support the Artists and Labels to KEEP the VIBE ALIVE. \nCheers MARKIEBEEZ\n\nGet every mix as I release them by SUBSCRIBING for FREE click the ITUNES icon below & Click FOLLOW ME!!	https://assets.podomatic.net/ts/a2/21/68/deepfunkymeb/3000x3000_11337731.jpg
1695	http://deephouseau.podomatic.com/rss2.xml	DHA Podcast | Deep House | Techno .	Deep House Australia	Based in Sydney, Australia, we are a small community of deep, tech house and techno fans.  We share our passion for music online.  Join our community on Facebook http://www.facebook.com/deephouseau	https://assets.podomatic.net/ts/b2/68/ab/deephouseau/3000x3000_8924015.jpg
1696	http://deepshitbaronvaughn.libsyn.com/rss	Deep S##! w/ Baron Vaughn	Deep S##! w/ Baron Vaughn	Professional s##! talker, Baron Vaughn sits down …	http://i1.sndcdn.com/avatars-000053354998-uyo60k-original.jpg
1697	http://deepsoulsessions.net/feed/podcast/	Deep Soul Sessions	ninamorena@gmail.com (Nina Morena)	Explore the deep and soulful side of house, afrobeats and more with Nina Morena	https://deepsoulsessions.net/musicsweetmusic/wp-content/uploads/powerpress/logo-832.jpg
1698	http://deepsoundmusic.podomatic.com/rss2.xml	DEEPSOUND MUSIC PODCAST	DeepSound Music	DeepSound Tuesdays is Max Julien’s newest live show on Techno.fm, featuring both of his DJ personas alternating between his two differing underground dancefloor styles from one week to the next – with a few surprises... \n\nThe veteran DJ/producer, who started spinning professionally in clubs in 1984, before joining Techno.fm in 2005, now merges his two previous shows into one weekly program, as the highly-rated former DeepTuesdays, featuring his deep, dark, and delicious house persona, now shares the airwaves with his progressive trance/trance alter-ego, Zouvi, to now become DeepSound Tuesdays. \n\nFurthermore, special guests will also be featured, with DJ sets from various DeepSound Music artists appearing on a regular basis. In fact, DeepSound Music is the parent company of both DeepSound Records and DeepMoon Records, Max Julien’s internationally-recognized house and trance labels.\n\nDeepSound Tuesdays is broadcast live on Techno.fm every Tuesday from 5 to 8 pm ET (22-1 GMT).	https://deepsoundmusic.podomatic.com/images/default/podcast-4-3000.png
1703	http://degrassi-online.com/podcast/podcast.xml	Degrassi Talks	Degrassi-Online.com	Degrassi Talks is all about discussing Degrassi! Each episode we talk about the latest Degrassi news, theories as to what is to come on the show, and anything else related to the Degrassi brand!	http://i54.tinypic.com/141qixz.jpg
1704	http://dekcollectors.podOmatic.com/rss2.xml	DJ Dlux  We Play Music Podcast	D.lux	The Original DJ Dlux Music Podcast,  Specialising in  House, Jungle, DnB, Garage, Hip Hop, Soul, RnB, Rare,& Dancehall. \nWe play music, but we don't play when it comes to music. ( Associated Brands, DejaVufm, Brain Records, Dek Collectors & We Play Music Live.)\n\n\nIf you download podcast and like, please leave a comment.. thanks	https://assets.podomatic.net/ts/e5/e0/7d/dekcollectors/pro/3000x3000_14269923.jpg
1705	http://del-potro.sakura.ne.jp/potrocast.xml	Del Potro Podcast	Ciefuengos INC.	Del Potro Podcast - ¿ Que Pasa ?	http://del-potro.sakura.ne.jp/mix/delpotro.jpg
1706	http://delavaud.podomatic.com/rss2.xml	What the Fuck is Electro ?	Clement .D & Destroynoize		https://assets.podomatic.net/ts/6e/a5/93/jackass-seventies/3000x3000_4750005.jpg
1707	http://delearte.podbean.com/feed/	Delearte	Editora Delearte	Podcast to learn and practice Spanish in 5 minutes (or less)	https://pbcdn1.podbean.com/imglogo/image-logo/451631/Untitled_design.jpg
1708	http://delicioustv.libsyn.com/rss	Delicious TV	All Art Media, Inc.	If you love Delicious TV's Totally Vegetarian on public television, watch host Toni Fiore as she whips up some of her favorites, like Creamy Chard Wontons, Hot Jamaican Jerk Tofu, a savory Tempeh Club Sandwich, and Creamy Tofu Pot Pies, even a carnivore can delight in. Come and savor the flavor.\n\nFind the ecoookbooks at delicioustv.com or check out our iPhone and iPad App 'VegEZ' and bring 75 of Toni's favorite recipes on your next grocery shopping trip.<!-- PodNova/b87e6a8062bf01e27c239b74beb5cf96 -->	https://ssl-static.libsyn.com/p/assets/5/a/9/4/5a940799cfc898c2/VegEZ_itunes_1400x_.jpg
1709	http://delozhizni.podfm.ru/rss/rss.xml	Дело жизни	PodFM.ru	Еженедельное ток-шоу "Дело жизни" посвящено профессиональному и личному счастью. В каждом выпуске мы представляем слушателям две профессии и две истории успеха. Героями программы становятся ценные кадры — люди, которые заняты любимым делом и готовы поделиться профессиональными секретами. Ведущий обсуждает с ними трудовые будни, зарплату, ремесло, вдохновение и планы на будущее. \n \n"Дело жизни" придумали люди, которые с удовольствием работают в кадровом портале Superjob.ru и школе интернет-маркетинга "Нетология".	http://file.podfm.ru/1/10/106/1063/images/lent_27507_big_38.jpg
1711	http://deltasniper.podspot.de/rss	Unser guuuter Podcast	Julian Gelius	Hier erzählen wir dinge rund um PC und sonstiges end guuutes Zeug^^ Infos unter \r\nwww.end-guuut.de.vu	\N
1713	http://demokratie-goettingen.de/radio/unterderlupe.xml	Unter der Lupe - Ein Blick auf Politik und Gesellschaft	Unter der Lupe	Die Lupe im Namen steht für genaue, fundierte, wissenschaftliche Arbeit und ordnet sich\ndamit in die Tradition des Göttinger Instituts für Demokratieforschung ein. Sie impliziert einen kritischen,\nhinterfragenden, scharf beobachtenden Blick auf alles, was mit Demokratie zu tun hat. Folgerichtig wird in jeder\n"Unter der Lupe"-Sendung unter anderem eine wissenschaftliche Analyse, und ein Politikerinterview angeboten. Außerdem steht mit "Wissen in vier Minuten" eine Rubrik bereit,\nmit der wir unserer Aufgabe der Politischen Bildung nachkommen und monatlich neue Begriffe der Politik erklären. Die "Lokale Perspektive" ordnet das jeweilige Thema \nsystematisch und anschaulich für die lokale Ebene ein. In der Rubrik "Wiederentdeckt" fragen wir, was Politiker und andere gesellschaftlich relevante Personen nach ihrem Rückzug aus der \nÖffentlichkeit machen. Die Rubrik "frisch geforscht" arbeitet schlussendlich dezidiert neue Erkenntnisse aus Forschungsprojekten unseres Instituts auf und präsentiert diese in ansprechender,\nauf ein breites Publikum abzielender Form. Themen der Sendungen sind Parteipolitik - von konservativ bis grün, Soziale Bewegungen und politischer Protest,\nWahlen, Extremismus und Populismus, Intellektuelle und Charismatiker, Jugend und Politik etc. Interviewpartner u.a. Jürgen Trittin, Klaus von Dohnanyi, \nHans-Christian Ströbele, Franz Walter, Julian Nida-Rümelin u.a.	http://www.demokratie-goettingen.de/radio/Logo_Schrift_Grau-200x135.jpg
1714	http://demonlobster.com/?feed=deomn-lobster	Demon Lobster » Sanity Claws Radio Feed	Deomn Lobster	Nerd culture with a crunchy outer shell.	http://demonlobster.com/wp-content/uploads/2011/10/sanity_claws_radio_600x600.png
1716	http://denalimusic.podomatic.com/rss2.xml	Denali	Denali	Denali was born Timmy J. Marcoux in Manchester N.H. on March 24th 1982 at the age of 7 he was introduced to rap music "My first clear memory of rap was my mom chasing me around the living room trying to take away my NWA Straight Outta Compton tape, yes i said tape!" -Denali from that time on it was just him and the music listening to such artist's as NWA, Public Enemy, 2 Live Crew, and more. as time progressed so did rap music and so did Denali after growing up through the death's of Christopher "Notorious B.I.G." Wallace and Tupac Shakur his love for the rap game grew listening to the artist's of the era from Boot Camp Click to Flipmode Squad, O.C., Mobb Deep, Nas, and the list goes on , Around that time Dancehall Reggae was on the rise and it wasn't below Denali's notice cuz at the age of 13 during class in Jr High he began writing Dancehall lyrics sometime after that those notebooks were stolen from his locker which some would've seen as setback not D, it only furthered his hunger for more. In 2002 linking up with some other local emcees Denali taught himself to record and engineer his own tracks. Shortly after that he was introduced to 2 emcees who would not only help him to progress but to eclipse the competition in the Granite state (Meta-4 Est 1986, Konflikk Est 1982) With the start of the group Saints of the Dark He began to make a buzz for himself through shows cd's and word of mouth of his skills throughout the state.In 2006 tired of the empty promises and "i know someone in the game" quotes Denali decided to start H1 Family Records and H1 Productions. Now Denali is a pro ready to take on the world so get out of the way if you're in it because as Denali's song goes "So please accept just what your role is, you're no opponent, because the world you're in's mine."	https://assets.podomatic.net/ts/c9/f9/62/denalih1/1400x1400_3961467.jpg
1717	http://denblahasten.libsyn.com/rss	Den blå hästen	Malin Åkersten Triumf	En podcast om Europas historia. Målad med stora penseldrag av min pappa, Ulf Åkersten! Tänkt att komma ut ungefär en gång i veckan. Frågor, tillägg, korrigeringar? Hör av dig på dbh@triumf.se!	https://thumborcdn.acast.com/FvWDMchqCjoH0oUPehzGHZdEuv8=/1500x1500/https://acastprod.blob.core.windows.net:443/media/v1/a0ce9fc0-3de0-4c4a-a0dc-11b63ec5fa05/dbhrod2-itlhlqa5.jpg
1719	http://deniseleeyohn.com/bites/feed/podcast/	Denise Lee Yohn	stuff@deniseleeyohn.com (Denise Lee Yohn)	brand leadership expert | speaker | author	http://deniseleeyohn.com/i/DLY600headshot.jpg
1720	http://dennisfromohio.podbean.com/feed/	Early Morning Runner	Dennis From Ohio	A pod cast that chronicles my five month long journey to run the Boston Marathon on an arthritic knee - then quit.	https://pbcdn1.podbean.com/imglogo/image-logo/89166/IMG_18890001.jpg
1721	http://dennishasapodcast.libsyn.com/rss	Dennis Has A Podcast	Dennis Has A Podcast	Dennis Holden talks with new friends and old, highlighting the talented people of New York City, while also talking about what matters most... sports, comedy, movies, music, TV, theater, fun news stories, professional wrestling and more!	https://ssl-static.libsyn.com/p/assets/5/a/7/e/5a7ef013fee19d10/DHAP_New_logo_iTunes.jpg
1722	http://dennishensley.libsyn.com/rss	DENNIS ANYONE? with Dennis Hensley	Dennis Hensley	"A poodocast about making things up and making things happen." L.A.-based writer-performer Dennis Hensley interviews a different creative person each week about what they do, why they do it, and how they keep it going. Past guests have included authors, actors, photographers, musicians, screenwriters, acrobats and one visual artist who makes cartoons centered around dead houseflies.	https://ssl-static.libsyn.com/p/assets/f/b/a/b/fbabcccb3d11c919/DennisAnyonenewSquare.jpg_-_1.jpg
1724	http://dennyhoban.podomatic.com/rss2.xml	St. Stephen Catholic Church, EGR, MI	Dennis Hoban		https://dennyhoban.podomatic.com/images/default/podcast-4-3000.png
1727	http://denver.granicus.com/Podcast.php?view_id=92	City and County of Denver: All Programming Audio Podcast	City and County of Denver		http://webcontent.granicusops.com/content/denver/images/denver8tv.jpg
1729	http://depts.washington.edu/uwmcorth/podcasts/UWTV.xml	Zen's University of Washington Orthopaedics and Sports Medicine Pod Experiment	Zen "The Podmaster" Seeker	The University of Washington Medical Center strives to lead the way in providing medical information to medical providers, patients and the general population with the latest in cutting edge technology.  Podcasting will all us to provide video and audio broadcasts in a way that allows of ease of downloading and viewing of content of portable devices.  The following casts are a test, and there are many more that have already been formated just waiting to join these pilot casts.  Please feel free to contact us here at the UW and visit us at: www.orthop.washington.edu	http://depts.washington.edu/uwmcorth/podcasts/PodImage.jpg
1730	http://deputyedtiorecn.podomatic.com/rss2.xml	ICISradio	Simon Robinson	The World's first podcast for the global chemicals industry brought to you by ICIS. That's some of the most seasoned of 100 professional journalists and reporters who cover the industry for ICIS Chemical Business magazine (incorporating European Chemical News and Asian Chemical News) and ICISnews. For more information on these subscription products check out http://www.icis.com	https://assets.podomatic.net/ts/05/7b/90/deputyedtiorecn/pro/3000x3000_436870.gif
1731	http://der-neue-hippokrates.podspot.de/rss	Der Neue Hippokrates	Der-Neue-Hippokrates	Der Neue Hippokrates ist eine interaktive Internetzeitung für das Gesundheitswesen. Sie können bei uns interaktiv unter einem Pseudonym Ihre Beiträge über das Gesundheitswesen veröffentlichen. Zu jedem Artikel können auch ohne Anmeldung Kommentare verfaßt werden. In unseren Podcast-Episoden stellen wir uns vor und veröffenlichen Berichte von unseren Nutzern sowie eigene Berichte unserer Redaktion, die in irgend einer Weise mit dem Gesundheitswesen zu tun haben.  Über unsere Internetzeitung sollen die verschiedenen Gruppen des Gesundheitssystems, die Patienten, die Ärzte Zahnärzte, Psychologen, Krankenschwestern und -pfleger, Ergotherapeuten, Physiotherapeuten selbst zu Wort kommen und ein Austausch zwischen diesen Gruppen verstärkt werden. Sie berichten,  wie die Situation in den Kliniken und Praxen ist, welche Konsequenz die Gesundheitspolitik im Detail hat und welche Verstrickungen dafür verantwortlich sind. Unsere Plattform möchte die Öffentlichkeit schaffen, die für einen Austausch und für nachhaltige Veränderungen notwendig ist.	\N
1733	http://derkinderkurierpodcast.podspot.de/rss	Der Kinder Kurier	Tanja Taube	Der Kinder Kurier-Podcast ist das Bonbon des Online-Magazins "Der Kinder Kurier" (www.kinderkurier.de). Der Kinder Kurier informiert, kommentiert aktuelle Ereignisse, beleuchtet Hintergründe und hinterfragt.\r\n\r\nDie Kinder Kurier PodShow ...kriegt auch dich!\r\n\r\nEure Post an: info@kinderkurier.de !	\N
1735	http://derootart.podOmatic.com/rss2.xml	De Root Art	De Root Art	A program of songs which i believe you like but you might have never heard. \n\nProgram hosted by Antonio Luna \nIt is a mix of tracks from different backgrounds. A collection of thoughts, expirences, and music. \nI put this program together thinking on you. So that you can have a diverse knowladge of music varying in all languages, cultures and genres. \nIn this program you will be able to listen to all types of music, from hip hop, soul, rock, and chill out. Give it a try. You have nothing to loose!	https://assets.podomatic.net/ts/52/a4/80/derootart/3000x3000_611166.jpg
1737	http://desdeeldfw.podbean.com/feed/	desdeeldfw	desdeeldfw	opinion personal de lo que pasa en el mundo	https://pbcdn1.podbean.com/imglogo/image-logo/113010/desdeeldfwdecolores.jpg
1738	http://desedes.podOmatic.com/rss2.xml	DF Radio	des fost	this podcast includes "tim and des show" and "fisher and saylor" and many more commin this season.	https://assets.podomatic.net/ts/14/e3/4f/desedes/3000x3000_12864885.jpg
1739	http://desert-life.up.seesaa.net/my_rss/my_rss_convert.rdf	Desert Life	TK	ビデオPodcastで砂漠の生活をアリゾナから紹介します。	http://desert-life.up.seesaa.net/image/DeserLife_top.jpg
1741	http://designagame.eu/category/podcasts/feed/	Design a Game » Podcasts	» Podcasts	the game design experience	http://designagame.eu/wp-content/uploads/powerpress/designagame-podcast-300.jpg
1742	http://designcritique.libsyn.com/rss	Design Critique: Products for People	Timothy Keirnan	Our show encourages usable designs for a better customer experience in products and services. Each episode is different, with the only constant being our demand that UX design make our lives better and provide long term value. If you care about design's impact on our modern quality of life, give us a listen. You will hear:\n* Critiques of products & services we've used thoroughly,\n* Interviews with people whose work or books we admire, and\n* Discussions of design methods we use in our own user experience research and design careers.	http://static.libsyn.com/p/assets/9/1/f/7/91f70f602086b006/designcritique_new.png
1743	http://designobserver.com/show.designmattersarchive.xml	Design Matters with Debbie Millman Archive: 2005-2009	Design Observer	Design Matters with Debbie Millman is an opinionated and provocative internet talk radio show. The show combines a stimulating point of view about graphic design, branding and cultural anthropology. In a business world dependent on change, design is one of the few differentiators left.	http://designobserver.com/images/podcast_designmattersarchive.jpg
1806	http://dig.abclocal.go.com/wls/podcast/newsspecialspod.xml	ABC7 Chicago - News Specials	WLS-TV	This video podcast channel will be updated as new items of interest become available.	http://abclocal.go.com/images/wls/podcasts/News_Pod.jpg
1744	http://designobserver.com/show.wetheconstitution.xml	We the Constitution	Design Observer	We the Constitution is a series of short videos designed to draw attention to the words of the United States Constitution. When asked, many people insist they know at least the preamble to the Constitution; when pressed, most can't remember past the third word. This project brings the focus back to the words themselves, and their relationship with the public life they help structure. Based on experimental projects begun while Andrew Sloat was in graduate school, the formats and techniques are inspired by the spirit of complexity and discovery that forged the original document in 1787.	http://observermedia.designobserver.com/images/podcast_wetheconstitution.jpg
1746	http://desolationangel.podbean.com/feed/	Desolation Angel Radio	Kip Williams	Music has it's own spirit, soul and life. It's a part of us, and tells our story, gives us a soundtrack, when we let it.	https://pbcdn1.podbean.com/imglogo/image-logo/100196/Profile_Pic_April_a_2020_2_.jpg
1747	http://desource.uvu.edu/artistseries/sd/podcast.xml	UVU Artist Series - SD	uvu artist series	The UVU Artist Series is a video podcast that features artists of all backgrounds and disciplines, taking a look at their experiences and perspectives within the creative process. We will typically release a new episode once a month.\n\nCurrently we are featuring artists actively involved in the communities of Utah County, but we are open to expanding the scope of the series down the road.	http://desource.uvu.edu/artistseries/sd/artist%20series%20logo.jpg
1749	http://dessertlioneldiscs.podbean.com/feed/	Dessert Lionel Discs	Sound of Science ltd	Lionel is a VW campervan and, inspired by the words and works of Carl Sagan, Lionel is The Spaceship of Our Imagination.\n\nHe likes to take people to the edge of the known universe but before they go, we like to chat to them about music, life and science while we share a delicious pudding.\n\nThis is Dessert Lionel Discs.	https://pbcdn1.podbean.com/imglogo/image-logo/561341/lionellogo.jpg
1752	http://destinyspirit.com/?feed=podcast	Destiny Spirit Ministries » Podcast Feed	Destiny Spirit Ministries	One word from God can change your life.	http://destinyspirit.com/images/ds_logo_300.jpg
1753	http://detective.libsyn.com/rss	Radio Detective Story Hour	Dennis Humphrey	Listen to radio's famous gumshoes and well-remembered cops. From the fog-bound shores of San Francisco to the insurance investigations of radio's famous expense account investigator; from the riotous actions of famous gang busters to the reality based exploits of Los Angles detectives.	http://static.libsyn.com/p/assets/4/f/4/5/4f456e06fb52f97d/radiodetectivehour_AA_copy.jpg
1754	http://detective.rnn.beta.libsynpro.com/rss	Radio Detective Story Hour	Dennis Humphrey	Listen to radio's famous gumshoes and well-remembered cops. From the fog-bound shores of San Francisco to the insurance investigations of radio's famous expense account investigator; from the riotous actions of famous gang busters to the reality based exploits of Los Angles detectives.	http://static.libsyn.com/p/assets/4/f/4/5/4f456e06fb52f97d/radiodetectivehour_AA_copy.jpg
1755	http://detectivepodcast.podomatic.com/rss2.xml	Detective Kusanagi Mystery Podcast	D.M. Wicks	A vampire detective with a werewolf as his partner. Follow this unlikely pair as they take on criminals and uncover secrets that may have been better left unknown.	https://detectivepodcast.podomatic.com/images/default/podcast-1-1400.png
1757	http://detektivconan-news.com/category/conancast/feed	ConanCast – Detektiv Conan zum Hören!	ps@detektivconan-wiki.com (ConanNews.org)	Der ConanCast ist ein Detektiv Conan Podcast von und für Fans der Anime- und Manga-Serie Detektiv Conan.<br />\nBei uns bekommt ihr monatlich alle wichtigen Ereignisse übersichtlich in einem Newspodcast präsentiert. Zudem erscheinen in unregelmäßigen Abständen Themenpodcast, in denen wir aktuellen Geschehnissen genauer auf den Grund gehen oder auch ältere Themen genauer beleuchten. Wir wünschen euch viel Spaß beim Hören und freuen uns auf euer Feedback!	https://conannews.org/wp-content/uploads/ConanCast-Logo-2016-3000x3000-scaled.jpg
1758	http://detektor.fm/feeds_fb/automobil/	AutoMobil	detektor.fm – Das Podcast-Radio	Immer montags, immer spannend und vor allem immer in Bewegung: die wöchentliche Serie rund um Auto, Verkehr und Navigation. "AutoMobil" wird präsentiert von atudo.de.	https://detektor.fm/wp-content/uploads/2018/11/2018_podcast-cover_automobil.jpg
1759	http://detektor.fm/feeds_fb/fortschritt/	Fortschritt – Der Technik-Podcast	detektor.fm – Das Podcast-Radio	Der Podcast "Fortschritt" zeigt, wie Technik unser Leben verändert. Visionäre Ideen, faszinierende Technik, spannende Trends - und die besten Geräte.	https://detektor.fm/wp-content/uploads/2018/10/2018_podcast-cover_fortschritt.jpg
1761	http://detfiktiveselskab.wordpress.com/feed/	detfiktiveselskap	\N	Radio Novas dramatiske alibi	https://s0.wp.com/i/buttonw-com.png
1763	http://deviantmedia.co.uk/deviantmedia.xml	Deviant Media Machinima Podcast	Rob Danton	Experiments with the medium of video in the virtual world of Second Life. The episodes are short clips of places and people going about their second lives. Updated at least once a month. Deviant Media has been televising the revolution since 2006.	http://deviantmedia.co.uk/Picture1300.jpg
1764	http://devivevoix.com/sl/mp3/quadri/rss_quadri.xml	Podcast Quadrivium Radio	Sylvain Lumbroso	Découvrez le quotidien palpitant de spécialistes qui concentrent leurs efforts pour faire progresser la science fondamentale. Une émission réalisée à Montréal en partenariat avec Québec Science.	http://www.devivevoix.com/sl/mp3/quadri/logo-quad-1400-blackw.jpg
1765	http://devminutes.cz/rss.xml	devminutes	devminutes	Rozhodli jsme se, že by jsme chtěli zkusit natoči…	http://i1.sndcdn.com/avatars-000058785997-rdit6v-original.png
1766	http://devonportbaptist.co.uk/feed/podcast/	Sermons – Devonport Baptist			https://www.devonportbaptist.co.uk/wp-content/uploads/2020/08/New-Normal.jpeg
1767	http://devopscafe.libsyn.com/rss	DevOps Cafe Podcast	Damon Edwards	In this interview driven show, John Willis and Damon Edwards take a pragmatic look at the technology, tools, and business developments behind the emerging DevOps movement.	https://ssl-static.libsyn.com/p/assets/3/7/3/b/373b94f19ddc2520/DevOpsCafe_AlbumArt.jpg
1768	http://devotionep.podomatic.com/rss2.xml	Devotion - EP	B.E.K.	Three kids having fun recording music.  Look out for the full album, featuring all new tracks, coming soon!	https://assets.podomatic.net/ts/56/90/57/devotionep/1400x1400_2123766.jpg
1771	http://dfuera.podspot.de/rss	dfuera.podspot.de	Sprachenzentrum, Friedrich-Schiller-Universität Jena	Tipps und Ratschläge für das (Über-)Leben in Deutschland.\r\nVon einer kleinen Gruppe aus einer kleinen Stadt im grünen Herzen Deutschlands.	\N
1772	http://dfw116kbphp.podomatic.com/rss2.xml	DFW116KB Power Hour Playback	DFW's 116 Kingdom Business by Deejay Kingdom Biz		https://assets.podomatic.net/ts/fe/9d/09/dfw116kb99741/3000x3000_7966327.jpg
1861	http://diskhouse.seesaa.net/index20.rdf	Disk House	Disk House	Disk House	http://diskhouse.up.seesaa.net/image/podcast_artwork.jpg
1774	http://dgmlive365.podomatic.com/rss2.xml	DGMLIVE365's Podcast	DGMLIVE365	DGM LIVE365 RADIO\n@DGMLIVE365\nDGMLIVE365RADIO #INTERNET, #COLLEGE & #BDS SPINS! http://dgmlive365.com DGMLIVE365@GMAIL.COM #TEXT REQUEST LINE 313.444.8650 http://www.facebook.com/Dgmlive365\nDET✈NY✈MIA✈LA✈ATL✈ · http://www.live365.com/stations/dgment\nhttp://dgmlive365.podomatic.com/	https://assets.podomatic.net/ts/20/f3/28/dgmlive365/0x0_7401096.jpg
1775	http://dgpodcast.podspot.de/rss	@last- Der DG-Podcast	Julian Ruß	Schülerradio des Dientzenhofer-Gymnasiums Bamberg - @last - der DG-Podcast	\N
1776	http://dgrodi.wordpress.com/feed/	TBCSermons	\N	Podcasts of Telos Bible Church Sermons	https://s0.wp.com/i/buttonw-com.png
1778	http://dharmatalk.libsyn.com/rss	Midwest Buddhist Temple Dharma Talks Podcast	Midwest Buddhist Temple - Chicago, IL	This is a weekly podcast of the Sunday service at the Midwest Buddhist Temple, a JodoShinshu Buddhist temple. The Midwest Buddhist Temple is a member of the Buddhist Churches of America, http://buddhistchurchesofamerica.org/home/.\n\nVisit our website  at http://mbtchicago.org or come to one of our services at 435 W. Menomonee St, Chicago, IL 60614, Visit our website for directions.	https://ssl-static.libsyn.com/p/assets/c/c/4/f/cc4f508428e3cc88/Dharma-Talks-Itunes-Wood.jpg
1779	http://dhbrgjon.podomatic.com/rss2.xml	Jon G's Podcast	Jon G	Enjoy Week 1	https://assets.podomatic.net/ts/36/ae/e0/dhbrgjon/3000x3000_7190766.png
1780	http://dhelio.podOmatic.com/rss2.xml	Descargas predicanet	Heliodoro Mira	APRENDER A REZAR Y MEDITAR BUSCANDO EL ENCUENTRO CON JESUCRISTO.\nDESCARGA LOS AUDIOS Y VIDEOS QUE TE AYUDEN A ESTAR MÁS CERCA DE DIOS EN MEDIO DEL MUNDO.	https://assets.podomatic.net/ts/fa/c7/8d/dhelio/pro/3000x3000_9353131.jpg
1781	http://dht.podomatic.com/rss2.xml	Darkhorse Training	Darkhorse Training	This podcast has been created as a sample resource for Student Services advisors in UK colleges of Further Education. It is part of an LSN skills development project, aimed at improving the I.T. skills of Student Services teams, providing them with useable resources and encouraging the further development of their own e-resources.	https://assets.podomatic.net/ts/b0/65/31/dht/1400x1400_606043.gif
1783	http://diabetespowershow.libsyn.com/rss	DiabetesPowerShow	Charlie Cherry	DiabetesPowerShow.com is your online diabetes support group, information source, and podcast. Hosted by three diabetes experts, this weekly podcast is committed to helping you build and live a life full of power, passion, and positive possibilities. This show is produced for all people affected by diabetes. This includes the patient and family members. Lots of information and resources for all things diabetes.	https://ssl-static.libsyn.com/p/assets/1/a/2/5/1a25b1a7fa238ebd/DiabetesPowerShowLogo2.jpg
1784	http://dialogoseningles.libsyn.com/rss	Dialogos en ingles	Vocatic	Dialogos en ingles es un recurso rapido y eficaz para mejorar tu nivel de reading, listening y vocabulario en ingles. Sin embargo, es muy difícil estudiarlo independientemente - HAY QUE DESCARGAR EL LIBRO CON LOS TEXTOS y el vocabulario que acompaña al curso. Si quieres echar un vistazo al libro se pueden descargar una unidad gratis en vocatic.com/itunes. Cada dialogo esta basado en una lista de 20 palabras elegidas de las mil palabras mas usadas en ingles. Esto significa se puede aprender vocabulario, escuchar y leer a la vez… por eso, dialogos en ingles es uno los mejores recursos de audio en internet… refuerza multiples habilidades.	https://ssl-static.libsyn.com/p/assets/8/6/f/c/86fc8dd01a17e891/0_new_linguamail.jpg
1786	http://dialogoverseas.podomatic.com/rss2.xml	Dialog Overseas	Dialog Overseas	Dialog Overseas: Hear what living overseas is really like. We answer the morally ambiguous questions.	https://assets.podomatic.net/ts/3f/82/dc/askdialogoverseas/1400x1400_10214074.jpg
1787	http://diamondsounds.podOmatic.com/rss2.xml	Diamond Sounds	Josh Haden	"To the mystic, the Philosopher's Stone is perfect love, which transmutes all that is base and 'raises' all that is dead." Manly P. Hall	https://assets.podomatic.net/ts/9c/18/ef/diamondsounds/3000x3000_610715.jpg
1789	http://dianefranklin.podbean.com/feed/	dianefranklin			https://djrpnl90t7dii.cloudfront.net/podbean-logo/powered_by_podbean.jpg
1790	http://diax.podOmatic.com/rss2.xml	Patricio Diax's Podcast Electronic Music	Patricio Diax	All the best Club, Dutch House and Moombahton track's \n\n\n\n\n\n\n\nFind Patricio Diax on : \n\nFacebook	https://assets.podomatic.net/ts/21/72/b5/diax/3000x3000_7166273.jpg
1793	http://dickdavies.podOmatic.com/rss2.xml	Dick  Davies' Podcast	Dick  Davies		https://dickdavies.podomatic.com/images/default/podcast-3-1400.png
1797	http://diddorol.podomatic.com/rss2.xml	The Kingdom of Diddorol behind-the-scenes Podcast	Larry Graykin	The Kingdom of Diddorol is a fictional kingdom that serves as the setting for all English Language Arts activities in Barrington (NH) Middle School's Room 244. It is the geographical component of the storyline of a game overlay, which presents and contextualizes all the usual ELA content in an alternative way. Each of the six provinces in Diddorol have a corresponding area in the classroom. Each province also symbolizes one of the Six Traits of Writing, and has a "mythology" of its own.\n\nIn this podcast, I'll share about my experiences in using a game overlay to change my delivery of the standard public school curriculum. Insights into what is working, and why -- as well as what is not, and how I'm coping with that -- will be explored, in the hope of encouraging other educators to experiment with this teaching method. A tip o' th' hat to Lee Sheldon, author of the text "The Multiplayer Classroom: Designing Coursework as a Game," the rulebook I used in developing Diddorol.	https://assets.podomatic.net/ts/81/3b/11/lgraykin/3000x3000_5016009.jpg
1801	http://die-halde.org/feed/		\N		https://diehalde.files.wordpress.com/2018/12/cropped-die-halde-e1543872688889.jpg?w=32
1802	http://diejumis.podspot.de/rss	diejumis // Jugendforum Wiedenest	jugendforumwiedenest.de	Gott ehren _Jugendgruppen dienen _Jugendliche inspirieren	\N
1803	http://dieseldadegen.podomatic.com/rss2.xml	Diesel and The Brain	Nikita Seliverstov	Talking about M:TG and Atlanta with a rotating group of characters	https://assets.podomatic.net/ts/21/cd/6e/sovietterror/1400x1400_7842282.png
1804	http://dietsoap.podOmatic.com/rss2.xml	Zero Squared	Douglas Lain	Zero Squared is a philosophy podcast from Zero Books. Zero publishes radical philosophy, aesthetics, film theory, experimental fiction, and anything else that smells faintly of the avant-garde. Our books aim not only to demonstrate how philosophical ideas are relevant to every day life, but also to change the terms of it. Douglas Lain is the host of this podcast and the publisher of Zero Books. He hosted the Diet Soap podcast out of this feed for five years. Zero Squared will continue the tradition of Diet Soap while giving Zero Books authors a chance to talk about their work.	https://assets.podomatic.net/ts/08/37/96/dietsoap/pro/3000x3000_10206098.gif
1805	http://dig-app.umg-cms.eu/_podcasts/cms/guaiaguaia.xml	Eine Revolution ist viel zu wenig	Universal Music GmbH	Eine Revolution ist viel zu wenig	http://dig-app.umg-cms.eu/_podcasts/cms/media/image/gg_albumcover_20130620151848_661_size1.jpg
1807	http://digestive.libsyn.com/rss	Диджестив от Саши и Каши		Подкаст о мобильных телефонах и технологиях. Каждую неделю Саша и Каша обсуждают самые интересные события недели	https://ssl-static.libsyn.com/p/assets/7/c/d/3/7cd364cc23181619/digcov.jpg
1808	http://digibuzzmixtapes.podomatic.com/rss2.xml	DigiBuzzMixtapes' Podcast	DigiBuzzMixtapes	A series of mixtapes featuring the dopest indie artist across the country!	https://digibuzzmixtapes.podomatic.com/images/default/podcast-3-3000.png
1809	http://digilander.libero.it/PubCastItalia/pubcastitalia.xml	PubCast Italia	mapo.pubcastitalia@gmail.com	Il pub virtuale, dove fermarsi per staccare la spina dal quotidiano! Musica e chiacchiere in compagnia di Mapo & Mirtilla	http://psstatic.podshow.com/images/shows/5767/shows/med/pubcast.jpg?db980a0c4276bb388e8a6b013f34d407
1810	http://digital-doctor-itunes.s3.amazonaws.com/the-digital-doctor.xml	The Digital Doctor	Dr Edward Wallitt	We are a small group of doctors and IT professionals who want to help clinicians harness the power of modern technology to improve their efficiency and level of patient care. We also want to make it easier for clinicians to get started implementing their own tech ideas.	http://digital-doctor-itunes.s3.amazonaws.com/images/digidoc_itune_logo.001.png
1811	http://digital.podbean.com/feed/	Ethereal Soundscapes by SK Infinity			https://pbcdn1.podbean.com/imglogo/image-logo/126799/logo.jpg
1812	http://digitalak.podomatic.com/rss2.xml	Black 7 Music Podcast	7Akil	Music from the planet Brooklyn, but the Digital era is over. This is my podcast page, old, alternative, and previously unpublished mixes are archived at my mixcloud page (http://tiny.cc/Blk7Music). All my mixes (new and old), podcast links, archive link, and iTunes subscription link can be found on the Black 7 Music facebook page http://tiny.cc/Black7. Not on fb, no worries I'll work something out real soon, or just hit me and I'll send you the links direct. Thanks for the love and as always... Enjoy!	https://assets.podomatic.net/ts/c3/24/48/digitalak/1400x1400_8496261.jpg
1814	http://digitalfilmikp.podomatic.com/rss2.xml	I/K/P "Digital Film"	Ruben/Sheri	We discuss everything and anything in the "Digital Film" world, so sit back relax and enjoy our rambles. Thank you all you sexy ppl =)	https://assets.podomatic.net/ts/02/65/44/impulsekitty16193/3000x3000_7941382.png
1816	http://digitalflotsam.org/rss.xml	Digital Flotsam	P.W. Fenton	Radio Free Radio's Digital Flotsam featuring P.W. Fenton	http://digitalflotsam.org/FlotsamITunes.jpg
1818	http://digitallyinfected.co.uk/radio/digitallyinfectedradioshow.xml	Digitally Infected Radio Show	Busho	Busho presents the DIGITALLY INFECTED RADIO SHOW (in association with GEARBOX) which is aired every 3rd Wednesday of the month @ www.fear.fm Each month Busho will bring you 30 minutes of the hottest tracks around and exclusive first listens to forthcoming releases on Digitally Infected and the 2nd half of the show will feature 30 minute guest mixes from some of the leading players in the hard dance world!	http://www.digitallyinfected.co.uk/radio/digitallyinfectedradio600x600.jpg
1819	http://digitalsaints.hipcast.com/rss/vineyard_community_church_of_marietta_ga.xml	Vineyard Community Church of Marietta GA	Mike O'Brien	A Podcast by Vineyard Community Church of Marietta, GA. Weekly teachings from Brad Inman, Pastor, and other guest speakers.	https://digitalsaints.hipcast.com/albumart/1001_itunes_1602524234.jpg
1820	http://digitalstash.net/podcasts/AGA/GASTRO/feed.xml	Gastroenterology	AGA	An engaging, informative mix of author interviews and expert commentary on the latest articles from Gastroenterology, hosted by the AGA journals' online editor, John F. Kuemmerle, MD, AGAF.	http://gastrodev.org/podcasts/AGA/GASTRO/images/itunes_image.jpg
1821	http://digitalstrategies.tuck.dartmouth.edu/rss/radiotuck/	Center For Digital Strategies	\N		\N
1822	http://digmeout.podbean.com/feed/	Dig Me Out - The 90s rock podcast	Dig Me Out	Weekly episodes digging up lost and forgotten 90s rock — in-depth album reviews, roundtable discussions, and artist interviews that reveal the unique story of the 90s.	https://pbcdn1.podbean.com/imglogo/image-logo/327252/DMO-WebAssetsArtboard-3-1400.jpg
1823	http://digress.libsyn.com/Ep2	The Digression Sessions	Josh Kuderna	Baltimore based comedian, Josh Kuderna (@JoshKuderna) is your host alongside his cohost Umar Khan, of The Digression Sessions. Listen as they chat with comedians, improvisers, musicians, creative people, and more from around our beautiful globe.	https://ssl-static.libsyn.com/p/assets/b/3/7/f/b37fa345bfa52ab1/IMG_3789.jpeg
1824	http://dilbert.wm.wizzard.tv/rss	Dilbert Animated Cartoons	Ringtales L.L.C.	He's alive!  Creator Scott Adams' world famous comic strip cubicle dweller Dilbert now walks and talks and sometimes gets the last line in a new, daily animated version from RingTales.  You can now enjoy Dogbert, Wally, Alice, the Pointy Haired Boss and all your favorite Dilbert characters in new installments five days per week. Animation that's addictive.  You can't watch just one.	http://static.libsyn.com/p/assets/6/2/7/f/627fa79f1736daa7/dilbert_podcast.jpg
1825	http://dimonvideo.podfm.ru/dv/rss/rss.xml	Еженедельный подкаст портала DimonVideo.ru	Дмитрий	Еженедельные новости проекта, беседы с интересными людьми, обзоры статей	http://file2.podfm.ru/12/128/1287/12879/images/lentava_14574_1_46.jpg
1826	http://dingdabell.com/feed.xml	Ding da Bell	John Ong	Two funny A-D-D Asian combination. A gay man, Ding, and a married woman, DaBell will guarantee a good fat dose of laughing therapy. Laughing with us regardless of our topic of choice. Ding is a Malaysian-born Chinese who now lives in the USA. DaBell was originally from Japan and is now married to an American and living in the USA. Ding and DaBell met in college and are now very close friends. "Ding da Bell, it's only you need!" Email: DingDaBell@gmail.com	https://dingdabell.com/images/DingDaBell1400.png
1827	http://dingdabell.com/ling.xml	Ding da Ling 叮的铃	John Ong	Two funny A-D-D Asian combination. A Malaysian in the USA, Ding, and a local Malaysian, Ling will guarantee a good fat dose of laughing therapy. Laughing with us regardless of our topic of choice. Ding is a Malaysian-born Chinese who now lives in the USA. Ling is a creative professional in Penang, Malaysia. Ding and Ling met through podcasting, and now became fast friends. Email: DingDaBell@gmail.com	https://dingdabell.com/images/DingDaLing1400.png
1828	http://dingdabell.com/loceng.xml	Ding da Loceng	John Ong	Gabungan dua pelawak Asia yang mengalami A-D-D. Seorang rakyat Malaysia yang menetap di Amerika Syarikat, Ding dan seorang tempatan Malaysia, Loceng akan menjamin ketawa yang tidak terhingga tanpa mengira topik pilihan mingguan.\nDing adalah seorang rakyat Malaysia berbangsa Cina yang kini menetap di Amerika Syarikat. Loceng adalah seorang profesional yang bergiat dalam bidang kreatif yang menetap di Pulau Pinang, Malaysia. Ding dan Loceng bertemu melalui Podcasting, dan kini telah menjadi teman akrib. Emel: DingDaBell@gmail.com	https://dingdabell.com/images/DingDaLoceng1400.png
1829	http://dinner4geeks.libsyn.com/rss	Dinner 4 Geeks	Scott Ryfun	Dinner 4 Geeks is just that.  A celebration of all things geek shared by four friends over a weekly dinner.  No area of geekology is off-limits.  This show is very entertaining, but beware!  It does suffer from a bad case of ADD!	https://ssl-static.libsyn.com/p/assets/0/0/2/3/0023a26c4ddad71b/Dinner_4_Geeks_logo2ai.jpg
1830	http://dinot.podOmatic.com/rss2.xml	Dino T.'s House Mixes	Dino T.	Hi everyone.\n\nWelcome to my podcast page.  Here you'll find a variety of mixes that I've done over the years.\n\nI will try to add at least one mix a month to keep you up to date with what I'm currently playing but please feel free to listen to the older ones too.  There may be a few classics in there that will trigger some fond memories for you.\n\nPlease let me know what you think of the mixes anyway by posting a comment on my page, sending me an email or becoming a fan.  All feedback is greatly appreciated.\n\nIt's been a long and interesting journey since those early days at the Ministry of Sound where it all began for me.  The upmost respect for those djs who encouraged me to start and for those who continue to inspire and give their support.\n\nI hope you enjoy listening to the podcast and if you do like any of the tracks within the mixes please keep downloading legal by purchasing a full version from one of the sites below using one of my favourite links.\n\nMany thanks in advance and I hope you enjoy the podcast!\n\nDino.	https://dinot.podomatic.com/images/default/podcast-3-1400.png
1835	http://directoalcorazon01.libsyn.com/rss	Directo al Corazón	Juan Ramos	Este podcast ha sido diseñado con el fin de fortalecer su caminar con Dios, aplicando principios Biblicos a su diario vivir. Muchas gracias por escucharlo. Este programa es dirigido por Juan Ramos Jr., Pastor de Ministerios Amor Internacional en Phoenix, AZ.	https://ssl-static.libsyn.com/p/assets/8/d/d/7/8dd7fe2a214ac760/Itunes_DAR.png
1838	http://dirtmed.libsyn.com/rss	Dirt Medicine Podcast	Pete Anderson, MD	Welcome to the Dirt Medicine Podcast, where the blood meets the mud!  The purpose of this podcast is to bring medical education to the combat medic no matter where he is on the globe.  Specifically I will be addressing new advances in trauma care, tactical combat casualty care updates, USSOCOM Advanced Tactical Practitioner scope of practice and protocols (TMEPs), and other topics of interest to the combat medic, SOCM, 18D, PJ, IDMT, IDC, corpsman, etc.  My focus is to educate the guy on the ground with the aid bag so he can provide the best possible care to our nation's finest.  Hooyah!	http://static.libsyn.com/p/assets/d/6/a/b/d6ab4383bfa2ea47/Dirtmed.jpg
1839	http://dirtybitpodcast.libsyn.com/rss	DirtybitPodcast	Dirtybitpodcast	Sherry reads erotic stories.Some written by her some written by guess authors	https://ssl-static.libsyn.com/p/assets/1/4/d/7/14d7e8122855c08b/dirty_bit.jpg
1840	http://dirtyboy.podomatic.com/rss2.xml	DirtyBOY's Presents THE 88's... PODCASTS	DirtyBOY	NYC ELECTRO/ACID HOUSE\n\nGlenn Davis Lee likesDirtyBOY&#039;s 88&#039;sCreate your Like Badge	https://dirtyboy.podomatic.com/images/default/podcast-3-3000.png
1842	http://dirtydisko.podomatic.com/rss2.xml	The Dirty Disko	The Dirty Disko	Subscribe for the very best in House music!\n\nIf you like the podcasts drop us a tweet @TheDirtyDisko\n\nwww.dirtydisko.co.uk	https://assets.podomatic.net/ts/c8/09/d5/johnlharrow/3000x3000_11691072.jpg
1843	http://dirtyhouse.podomatic.com/rss2.xml	Dirty House Podcast	Dirty House	**Welcome to the Dirty House Podcast by Sebastien Jl .\nEvery month a new podcast will be available.\n**Bienvenue sur les Podcast Dirty House de SebastienJL.\nChaque mois un nouveau Podcast sera disponible.	https://assets.podomatic.net/ts/eb/f5/78/podcast55439/3000x3000_12801696.jpg
1844	http://dirtyt.podomatic.com/rss2.xml	Dirty T's Podcast	Dirty T		https://assets.podomatic.net/ts/c4/c2/29/anthonythanos50474/0x0_7349924.jpg
1845	http://dirtytackle.podbean.com/feed/	Dirty Tackle	Samuel Green/Tom Field	Dirty Tackle is your laugh-filled, viciously light-hearted take on the hilarious world of football. Every week is a 10-15 minute joke-fest of topical football humour......	https://pbcdn1.podbean.com/imglogo/image-logo/118132/DTb2copy.jpg
1846	http://discoscratch.co.uk/?feed=podcast	Disco Scratch Radio	steven.welton@gmail.com (Disco Scratch Radio)	Join Waxer every week from 9pm to 11pm GMT broadcasting from the Palace Of Villainy, playing True School Hip Hop & featuring interviews, news, gig information & opinion.  The liveliest UK Hip Hop show around...	https://discoscratch.co.uk/wp-content/uploads/powerpress/Disco_Scratch_Radio_Logo_Square_iTunes-601.jpg
1847	http://discostu.podOmatic.com/rss2.xml	Selections from... One Nation Under A Groove	Disco Stu	DJ DS a.k.a. Disco Stu brings you mixes of Trance, Downtempo, Drum'n'bass, Funk, Soul & Hip-Hop mixes.  This podcast features highlights and selections from the main One Nation Under A Groove podcast.  Check the links for access to mixes on your favorite platform:\n\nHomePage: http://onenationunderagroove.net\nTwitter: https://twitter.com/disco6stu9\nInstagram: https://www.instagram.com/lediscostu/\nSoundcloud: https://soundcloud.com/disco6stu9\nMixcloud: https://www.mixcloud.com/ben-stewart2/	https://assets.podomatic.net/ts/b7/8e/66/discostu/3000x3000_606124.jpg
1848	http://discoverlife.podomatic.com/rss2.xml	Discoverlife.gr's Podcast	Discoverlife.gr		https://assets.podomatic.net/ts/de/29/f1/theodorek/1400x1400_8436930.jpg
1850	http://discoverspanish.com/podcasts/feed2.php	Learn to Speak Spanish with Discover Spanish	Johnny Spanish	It's fast, it's fun, and it's easy! Just 3 easy steps: 1. Subscribe to languagetreks.com to take full advantage of our award winning interactive language learning system. 2. Spend only 15 minutes a day with our cast of native speaking characters who actively engage you in learning to speak Spanish. 3. Try out our free podcasts while you are on the go and would prefer to review using your iPod or mp3 player. It’s that simple! Thousands of students are using our program with great success and very little effort. languagetreks.com is for all ages 9-99. Come join us today!	http://languagetreks.com/podcasts/discoverspanish_podcast_1400-optimized.jpg
1857	http://discussions.mnhs.org/collections/?feed=podcast	Museum Collections Up Close : MNHS.ORG	Minnesota Historical Society	Every object tells a story, and Collections Up Close presents short, illustrated features that highlight the stories and history behind selected items in the Minnesota Historical Society's museum collections.	http://discussions.mnhs.org/collections/wp-content/themes/mhs/MHS_Upclose_badge_small.png
1858	http://disgeek.libsyn.com/rss	The DisGeek Podcast - Your Guide to the Disneyland Resort	Daniel Hale	A Bi-Weekly Guide to the Disneyland Resort.	https://ssl-static.libsyn.com/p/assets/b/f/2/4/bf241b7b207bf644/disgeek-album-art-new.jpg
1859	http://disguistocast.podomatic.com/rss2.xml	Disguist-o-cast	Ben	Just two lesbians and a gay guy talking about awkward and embarrassing situations... Disguist-o-cast cause you want it. xD	https://assets.podomatic.net/ts/75/a9/88/disguistocast/1400x1400_3747942.jpg
1860	http://dishoom.podOmatic.com/rss2.xml	MumBai Mafia 4	MumBai  Mafia	Classic bollywood funk & disco	https://dishoom.podomatic.com/images/default/M-3000.png
1875	http://dissonance.libsyn.com/rss	DISSONANCE	Danger Mike	DISSONANCE is a biweekly music and talk show on community station Radio CPR 101.7 FM in Washington, DC, focusing on the underground music world in the nation's capital and beyond. Each episode features a different guest DJ and interview subject from the punk or artistic community.\n\nPrevious guests include members of the Bad Brains, Minor Threat, Fugazi, Government Issue, Bratmobile, Q and not U, The Dismemberment Plan, Black Market Baby, Darkest Hour, Damnation A.D., Scream, Gray Matter, Nation of Ulysses, The Make Up, Slickee Boys, Marginal Man, Velocity Girl, Eggs, Frodus, Battery, the Goons, the Suspects, Majority Rule, Edsel, Fairweather, Striking Distance, Worn Thin, Del Cielo, Crispus Attucks, Trial by Fire, Beauty Pill, Smart Went Crazy, Lion of Judah, Pulling Teeth, 86 Mentality, Integrity and DC graffiti artist BORF.\n\nTuesday nights\n9:00 pm\n101.7 FM\nWashington, DC	https://ssl-static.libsyn.com/p/assets/b/d/c/7/bdc70c41093bdf4f/iTunes_logo_copy_1.jpg
1876	http://dissonancepod.libsyn.com/rss	Cognitive Dissonance	Tom Curry	Every episode we blast anyone who gets in our way. We bring critical thinking, skepticism, and irreverence to any topic that makes the news, makes it big, or makes us mad. It’s skeptical, it’s political and there is no welcome mat.	https://ssl-static.libsyn.com/p/assets/4/b/d/b/4bdbb3bb7306ab68/cd_logo_itunes.jpg
1877	http://districttrivia.podomatic.com/rss2.xml	We Don't Know Either	City Trivia	Play along with the guests (all pub trivia staff or hosts) to figure out the answer to the questions. Each episode is a quick 20-30 minutes and features multiple interesting facts from random categories that vary each week, so you'll never know what you're going to learn about!\n\nWe may write the questions... but We Don't Know Either.	https://assets.podomatic.net/ts/94/09/eb/nick98815/pro/3000x3000_12705157.jpg
1878	http://distrikt.podomatic.com/rss2.xml	DISTRIKT	DISTRIKT	A weekly electronic music podcast featuring industrial-strength DJ mixes from DISTRIKT - A San Francisco-based non-profit music collective and Burning Man sound camp. For more information on DISTRIKT, visit us at at www.distriktcamp.org	https://assets.podomatic.net/ts/5c/1d/16/distrikt/3000x3000_5167368.jpg
1879	http://disturbedbeats.jellycast.com/podcast/feed/20	Disturbed Beats Mix Series	disturbedbeats	Disturbed Beats was started back in 2007 as a music blog featuring names such as Riva Starr, Mowgli, HiJack, Lee Mortimer etc sending in free music and mixes for download aswell as showcasing some up and coming producer. In 2008 we started the Disturbed Beats mix series with mixes from HiJack, His Majesty Andre, Tom EQ, Jay Robinson and more, now its time to bring the mix series to your iPod! Find all tracklisting @ http://disturbedbeats.blogspot.com or www.disturbedbeats.net\n\nDon't forget to subscribe to get the latest mix as soon as it's available.	https://disturbedbeats.jellycast.com/files/db-mixseries-300.jpg
1881	http://divanikkiz.podomatic.com/rss2.xml	Nikki Z Hot 20 Countdown	Nikki Z Hot 20	#1 Syndicate Caribbean Radio Show Worldwide! Official Worldwide Dancehall Hot 20 Countdown	https://assets.podomatic.net/ts/b4/7b/e0/divanikkiz/1400x1400_10228495.jpg
1882	http://divefilm.com/podcasts/podcast.xml	DiveFilm Podcast Video	Mary Lynn Price	Showcasing some of the best underwater short films being produced today by filmmakers all over the world. For High Definition versions of these underwater video podcasts, please check out our DiveFilm HD Video Podcast here at iTunes! Featuring footage of all kinds of marine life, short films by divers all over the world, interviews with interesting people, and information on underwater imaging.	http://divefilm.com/podcasts/podcastlogo.jpg
1883	http://divefilmhd.com/podcasts/podcast.xml	DiveFilm HD Video	Mary Lynn Price	High Definition videos of the underwater world for your computer, iPad, iPhone, iPod, and HDTV! Showcasing some of the best high definition underwater short films being produced today from all over the world. Featuring beautiful images of the underwater world, marine life large and small, interviews with interesting people, and updates on underwater imaging. Produced in association with Wetpixel.com.	http://divefilmhd.com/podcasts/divefilmhdlogo1400.jpg
1885	http://diversspace.wm.wizzard.tv/rss	Divers Space - A Scuba Diving Podcast	Syed	Divers Space records a bi weekly podcast in St. Georges, Bermuda. Our\nhost Stephan Harrold reviews the latest scuba diving products, dive sites,\nand talks to scuba diving experts, scientists and professionals from all\nover the world. The Divers Space team also consist of Hyperbaric doctors,\ndive instructor, dive photographers who will be on the shows to give tips\nto our audience.	http://static.libsyn.com/p/assets/8/b/d/1/8bd19fa8f93e4edc/raw.jpg
1887	http://divijsatija.podomatic.com/rss2.xml	Divij's Trance 4 Life Podcast	Divij Satija	Divij's Trance 4 Life Podcast!\nStay Calm and Enjoy!	https://assets.podomatic.net/ts/95/aa/db/divijsatija/1400x1400-292x292+6+8_8349128.jpeg
1888	http://divinemercy.podbean.com/feed/	Divine Mercy Podcast - Faribault, MN			https://pbcdn1.podbean.com/imglogo/image-logo/428994/IMG_1443.jpg
1889	http://divineoffice.org/?feed=nokia	Divine Office – Liturgy of the Hours of the Roman Catholic Church (Breviary)	admin@divineoffice.org (Divine Office (DivineOffice.org))	Daily scripture readings, psalms, and prayers that follow in the ancient traditions of the Church yet made to feel contemporary through talented readers and remarkable music. Follow along using the session outlines at DivineOffice.org.  <br />\n<br />\nFrom ancient times the Church has had the custom of celebrating each day the liturgy of the hours. In this way the Church fulfills the Lord's precept to pray without ceasing, at once offering praise to God the Father and interceding for the salvation of the world. For this expressed purpose, the recordings of the Hours presented here are intended to expand awareness of this Liturgy, introduce and practice the structure of this prayer, and to assist in the recitation of the Liturgy in small groups, domestic prayer and where common celebration is not possible.	https://divineoffice.org/wp-content/uploads/2008/08/divineoffice-podcastlogo144.png
1890	http://divineoffice.org/category/daytime-prayer/feed/	Divine Office Daytime Prayers	admin@divineoffice.org (Divine Office (DivineOffice.org))	Daily scripture readings, psalms, and prayers that follow in the ancient traditions of the Church yet made to feel contemporary through talented readers and remarkable music. Follow along using the session outlines at DivineOffice.org.  <br />\n<br />\nFrom ancient times the Church has had the custom of celebrating each day the liturgy of the hours. In this way the Church fulfills the Lord's precept to pray without ceasing, at once offering praise to God the Father and interceding for the salvation of the world. For this expressed purpose, the recordings of the Hours presented here are intended to expand awareness of this Liturgy, introduce and practice the structure of this prayer, and to assist in the recitation of the Liturgy in small groups, domestic prayer and where common celebration is not possible.	http://divineoffice.wpengine.com/wp-content/uploads/2008/08/divineoffice-podcastlogo144.png
1950	http://djalchurchill.podOmatic.com/rss2.xml	dj al churchill's Podcast	Al Churchill	Dance music at it's finest.	https://assets.podomatic.net/ts/e2/c0/db/djalchurchill/1400x1400_3216963.jpg
1891	http://divineoffice.org/category/evening-prayer/feed/	Divine Office – Liturgy of the Hours of the Roman Catholic Church (Breviary)	admin@divineoffice.org (Divine Office (DivineOffice.org))	Daily scripture readings, psalms, and prayers that follow in the ancient traditions of the Church yet made to feel contemporary through talented readers and remarkable music. Follow along using the session outlines at DivineOffice.org.  <br />\n<br />\nFrom ancient times the Church has had the custom of celebrating each day the liturgy of the hours. In this way the Church fulfills the Lord's precept to pray without ceasing, at once offering praise to God the Father and interceding for the salvation of the world. For this expressed purpose, the recordings of the Hours presented here are intended to expand awareness of this Liturgy, introduce and practice the structure of this prayer, and to assist in the recitation of the Liturgy in small groups, domestic prayer and where common celebration is not possible.	https://divineoffice.org/wp-content/uploads/2008/08/divineoffice-podcastlogo144.png
1892	http://divineoffice.org/category/morning-prayer/feed/	Divine Office – Liturgy of the Hours of the Roman Catholic Church (Breviary)	admin@divineoffice.org (Divine Office (DivineOffice.org))	Daily scripture readings, psalms, and prayers that follow in the ancient traditions of the Church yet made to feel contemporary through talented readers and remarkable music. Follow along using the session outlines at DivineOffice.org.  <br />\n<br />\nFrom ancient times the Church has had the custom of celebrating each day the liturgy of the hours. In this way the Church fulfills the Lord's precept to pray without ceasing, at once offering praise to God the Father and interceding for the salvation of the world. For this expressed purpose, the recordings of the Hours presented here are intended to expand awareness of this Liturgy, introduce and practice the structure of this prayer, and to assist in the recitation of the Liturgy in small groups, domestic prayer and where common celebration is not possible.	https://divineoffice.org/wp-content/uploads/2008/08/divineoffice-podcastlogo144.png
1893	http://divineoffice.org/category/night-prayer/feed/	Divine Office Night Prayer (Compline)	admin@divineoffice.org (Divine Office (DivineOffice.org))	Daily scripture readings, psalms, and prayers that follow in the ancient traditions of the Church yet made to feel contemporary through talented readers and remarkable music. Follow along using the session outlines at DivineOffice.org.  <br />\n<br />\nFrom ancient times the Church has had the custom of celebrating each day the liturgy of the hours. In this way the Church fulfills the Lord's precept to pray without ceasing, at once offering praise to God the Father and interceding for the salvation of the world. For this expressed purpose, the recordings of the Hours presented here are intended to expand awareness of this Liturgy, introduce and practice the structure of this prayer, and to assist in the recitation of the Liturgy in small groups, domestic prayer and where common celebration is not possible.	http://divineoffice.wpengine.com/wp-content/uploads/2008/08/divineoffice-podcastlogo144.png
1894	http://divineoffice.org/category/office-of-readings/feed/	Divine Office – Liturgy of the Hours of the Roman Catholic Church (Breviary)	admin@divineoffice.org (Divine Office (DivineOffice.org))	Daily scripture readings, psalms, and prayers that follow in the ancient traditions of the Church yet made to feel contemporary through talented readers and remarkable music. Follow along using the session outlines at DivineOffice.org.  <br />\n<br />\nFrom ancient times the Church has had the custom of celebrating each day the liturgy of the hours. In this way the Church fulfills the Lord's precept to pray without ceasing, at once offering praise to God the Father and interceding for the salvation of the world. For this expressed purpose, the recordings of the Hours presented here are intended to expand awareness of this Liturgy, introduce and practice the structure of this prayer, and to assist in the recitation of the Liturgy in small groups, domestic prayer and where common celebration is not possible.	https://divineoffice.org/wp-content/uploads/2008/08/divineoffice-podcastlogo144.png
1895	http://divinylechodjs.podOmatic.com/rss2.xml	Oakland / SF Bay Area House Music	rafi acevedo	Sounds of Oakland Underground of the San Francisco Bay Area. We are talking some serious house music such as Garage, Deep house, Tech House and minimal techno. You will also find sprinkles of downtempo, funk and rare soul. Actually anything that sounds good can be found here. Believe that!\n\nCome on into the Suga Shack where beautiful music lives and thrives!	https://assets.podomatic.net/ts/c2/83/13/divinylechodjs/3000x3000_10727559.jpg
1898	http://dizhostinteractive.podomatic.com/rss2.xml	Diz Host Interactive	Diz Jensen	Diz Host Interactive digitizes the magic of Disney to put it right into your living room.  It also gives you a place to voice your opinion on different topics in the Disney Online Community.	https://assets.podomatic.net/ts/33/fe/6c/dizhostinteractive/1400x1400_1992200.jpg
1900	http://dj-643jorge62243.podomatic.com/rss2.xml	Fire Element Sessions Mixed by DJorge Caballero	DJorge Caballero	Fire Element Sessions Mixed by Andherson All The Best & New in Trance Music, Every 2 Weeks. Genre: Trance, Pro gressive, Techno. \n\nGenre: Trance, Progressive, Techno \n\nBio: \nJorge Alberto Caballero Diaz aka. DJorge Caballero, Andherson borned in Mexico, D.F. On July 24, 1990. \nSUPPORTED By PAUL OAKENFOLD, Manuel Le Saux, Many others artist Nowadays jorge possesses infinity of tracks produced and remixed, in which all the electronic styles such as electro, tech trance, tech house, etc. For him does not exist an specific genre. \n\nJorge Alberto Caballero \nPromos, Remix Requests : djorgecaballeromusic@gmail.com \nLinks: \nDJ Concept :http://www.djconcept.com.mx/djorge-caballero \nFacebook: http://www.facebook.com/DJorgeCaballero \nTwitter :http://www.twitter.com/djorgecaballero \nSoundcloud: http://soundcloud.com/djorgecaballero	https://assets.podomatic.net/ts/df/e8/a2/dj-643jorge62243/3000x3000_7026580.jpg
1901	http://dj-andy-b.podOmatic.com/rss2.xml	dj-andy-bee Deep n Soulful House # RNB Soul Podcast	Andy Bonney		https://assets.podomatic.net/ts/9a/f3/3a/dj-andy-b/pro/3000x3000_2015829.jpg
1902	http://dj-basstos.backdoorpodcasts.com/index.xml	DJ BASSTOS OFFICIAL PODCAST	DJ BASSTOS	DJ BASSTOS aka THE FULL DJ SHOW	http://dj-basstos.backdoorpodcasts.com/uploads/items/dj-basstos/dj-basstos-official-podcast.jpg
1903	http://dj-bb.podOmatic.com/rss2.xml	dj-bb Electro House Music	dj-bb	Dirty Electro Funky House music spun by dj-bb	https://assets.podomatic.net/ts/75/8e/31/dj-bb/3000x3000_5594415.jpg
1904	http://dj-dannymansfield.podomatic.com/rss2.xml	DJ Danny Mansfield presents Carpe DM	Danny Mansfield	Hi and welcome to the latest edition of Carpe DM.	https://assets.podomatic.net/ts/9e/2d/33/dj-dannymansfield/1400x1400_8735492.jpg
1951	http://djalexanderla.podOmatic.com/rss2.xml	ALEXANDER	ALEXANDER	ALEXANDER was Born in Cuba, surrounded by musical inspiration, Alexander's love of music surfaced early, and by age 19 he was working as a dj in LA learning the ropes from a diverse talent pool. In 1999 he began his first residency at Circus Disco, and during his four years there, he developed the large loyal following he keeps to this day. Currently a resident dj of Nyc's newest mega club, VIVA Saturdays & Reflex Afterhours in LA.	https://assets.podomatic.net/ts/0b/93/18/djalexanderla/3000x3000_12026016.jpg
1905	http://dj-deal.backdoorpodcasts.com/index.xml	Dj Deal - The Party Shaker Podcast	Dj Deal	Welcome to the Dj Deal aka The Party Shaker's Podcast !\nFind here a 1H mix every month, delicious cocktail between electronic and urban music, a mixture of news and classics, that you can listen everywhere !\nTo follow all the latest news and tour dates, go visit his website : www.djdeal.fr\n--\nBienvenue sur le podcast de Dj Deal !\nRetrouvez chaque mois une heure de show éclectique et accessible, délicieux cocktail entre les musiques électroniques et les sonorités black music, mélange de nouveautés et de classics, à écouter partout !\nPour suivre toute son actualité et son agenda, allez visiter son site internet : www.djdeal.fr	http://dj-deal.backdoorpodcasts.com/uploads/items/dj-deal/dj-deal-party-shaker-podcast.jpg
1906	http://dj-def-craig.backdoorpodcasts.com/index.xml	Dj Def Craig - The Podcast	Dj Def Craig	Dj Def Craig s’est produit dans les plus grands club parisiens tels que le Man Ray (15 15), Le Palais M, la Maison Blanche, la Suite, le Cab, le Milliardaire, le Bus Palladium, les Bains Douches, le Redlight, l’Elysée Montmartre, le Gibus, etc. Il a eu l occasion d exercer ses talents sur la scène internationale (The City (Cancun, Mexique), Paradise (Marrakech, Maroc), Sofitel, Beach Club & Salammbô, (Agadir, Maroc), Rosa Beach (Monastir, Tunisie), Base Bar (MTV - Eilat, Israël), Bungalow (Tel-Aviv, Israël), Gallerie (Zagreb, Croatie) Il a également joué, entres autres, aux côtés de Dj Abdel, Big Ali, Dj Snake, Mathieu Bouthier, Dan Marciano, Greg Di Mano et a fait une apparition dans la célèbre émission du « RnB Chic » de Dj Sub Zero sur Radio FG. Il compte à son actif 2 mix-tapes : RnB Summer Style, Shake Da Ass. Grâce à sa persévérance, ce jeune Dj talentueux a su s’imposer très vite sur la scène parisienne en proposant des sets éclectiques. Il est reconnu par ses pairs comme l’un des Dj’s les plus prometteurs de sa génération. Découvrez dès maintenant son podcast	http://dj-def-craig.backdoorpodcasts.com/uploads/items/dj-def-craig/dj-def-craig-the-podcast.jpg
1907	http://dj-ewone.backdoorpodcasts.com/index.xml	EwONE! Radio Mixshow - Official Podcast	EwONE! (Instagram: @djewone / Twitter: @djewone / FB: @djewone)	FRANCAIS: EwONE! vous invite à télécharger chaque semaine le podcast de son émission radio (sans les speaks et sans les coupures pubs), avec les dernières nouveautés HH/R&B et des sessions "classics" à ne pas manquer. Alors faites-vous plaisir !!!\nENGLISH: EwONE! invites you every weeks to download the podcast of his radio mixshow (without speaks and commercials breaks) including the latest news HH/R&B as well as some classics! Go ahead and enjoy it !!!	http://dj-ewone.backdoorpodcasts.com/uploads/items/dj-ewone/ewone-radio-mixshow-official-podcast.jpg
1908	http://dj-ghen-da-paul.backdoorpodcasts.com/index.xml	DJ GHEN DA PAUL OFFICIAL PODCAST	ghen da paul	DJ GHEN DA PAUL\nRésident du Kiss Club, l'un des clubs hip hop de référence en Allemagne, Dj Ghen Da Paul est sans conteste l'un des Djs les plus talentueux et les plus prometteurs de sa génération.\nSurnommé "CLUB KILLER" Le Dj Français enchaîne avec brio les premières parties de prestigieux artistes internationaux comme Sean Paul, Omarion, The Game, French Montana, Ryan Leslie, Ace Hood, T- Pain, Lloyd Banks, Fatman Scoop, Red Cafe, 50 Cent ou encore Ja Rule et enflamme les soirées les plus hot de France et d'Allemagne en passant par la Suisse, la Belgique ou encore la Chine et les Dom Tom.\n---------------------------------------------------------------------------------------------------------------------------------\nAs a resident DJ at one of Germanys leading Hip Hop Clubs ‘Kiss Club’ DJ Ghen Da Paul is without doubt one of the most talented and promising DJs of his generation.\nKnown as "CLUB KILLER" the french DJ from smoothly and skilfully connects international artists such as Sean Paul, Omarion, The Game, French Montana, Ryan Leslie, Ace Hood, T- Pain, Lloyd Banks, Fatman Scoop, Red Cafe, 50 Cent and Ja Rule, producing some of the hottest parties worldwide, from France, Germany, Switzerland and Belgium to China and Reunion Islands	http://dj-ghen-da-paul.backdoorpodcasts.com/uploads/items/dj-ghen-da-paul/dj-ghen-da-paul-official-podcast.jpg
1910	http://dj-he-man-is.podomatic.com/rss2.xml	DJ He Man Is! Podcast	DJ He Man Is!	Thanks for checking out my page! My sets contains a diversity of dance music from all types of House music and other genres. I just love to see people having fun & dancing, new music and keep evolving through out music & time. I'm a big supporter of music from producers that make music from a computer in a small basement to garage all the way the big music studios. So if you're a producer that has a track worth listening HMU, G@m & too all my fans & supporters thanks for your support and spread the love!	https://assets.podomatic.net/ts/22/f0/98/podcast8025677498/3000x3000_5110813.jpg
1911	http://dj-hymr.backdoorpodcasts.com/index.xml	DJ HYM-R - OFFICIAL PODCAST	Dj Hym-R	//BOOKING DJ HYM-R// liberdadeagency@gmail.com \nInstagram: dj_hymr\nFacebook: dj hym-r\nSnap: fafense4820	http://dj-hymr.backdoorpodcasts.com/uploads/items/dj-hymr/dj-hym-r-official-podcast.jpg
1912	http://dj-jekey.backdoorpodcasts.com/index.xml	DJ JEKEY OFFICIAL PODCAST	DJ JEKEY	Here you can listen to my mixes of different kinds of music from the best of funk to the latest in Nu / Disco & Indie / Dance through the latest in urban music, Hip-Hop, R & B, Dancehall, Reggae. Hope you enjoy it.	http://dj-jekey.backdoorpodcasts.com/uploads/items/dj-jekey/dj-jekey-official-podcast.jpg
1913	http://dj-joy.backdoorpodcasts.com/index.xml	DJ JOY - OFFICIEL PODCAST	DJ JOY OFFICIEL	FACEBOOK : DJ JOY OFFICIEL\nINSTAGRAM : DJJOYOFFICIEL\nSNAPCHAT : DJJOYOFFICIEL\nYOUTUBE : DJJOYMUSIK\nDEEZER : DJJOYOFFICIEL	http://dj-joy.backdoorpodcasts.com/uploads/items/dj-joy/dj-joy-officiel-podcast.jpg
1914	http://dj-jvc.podOmatic.com/rss2.xml	DJ JVC (DJ James Vincent NYC)	DJ JVC (DJ James Vincent NYC)	Two turntables--usually no mic--lots o'records--some help from Serato--always a fly mix of--hip hop, rock, reggae(ton), house, classics, electronic, mashups--maybe one--maybe all--check me out--DJ JVC \n\nMore mixes on DJ James Vincent NYC podcast: \n\nwww.djjamesvincentnyc.podomatic.com	https://assets.podomatic.net/ts/5f/79/0b/dj-jvc/3000x3000_1108293.jpg
1915	http://dj-kc.backdoorpodcasts.com/index.xml	HOT CAST	DJ KC	The official HotSundayNights podcast (Mondial @ Beek, The Netherlands)	http://dj-kc.backdoorpodcasts.com/uploads/items/dj-kc/hot-cast.jpg
1916	http://dj-kifinf.podomatic.com/rss2.xml	Dj KiFinF in Ze MiX	Dj KiFiinF		https://assets.podomatic.net/ts/c2/ce/84/kifinf83/3000x3000_7484848.jpg
1917	http://dj-killtrax.podomatic.com/rss2.xml	dj killtrax _ Beast Dj  Podcast	Dj KillTrax_Beast Dj		https://assets.podomatic.net/ts/2e/2c/ed/dj-killtrax/3000x3000-477x477+94+163_11429927.jpg
1918	http://dj-kiss.backdoorpodcasts.com/index.xml	DJ KISS - MY OFFICIAL PODCAST	Dj Kiss	Dj Kiss - Official Podcast	http://dj-kiss.backdoorpodcasts.com/uploads/items/dj-kiss/dj-kiss-my-official-podcast.jpg
1969	http://djazas.podOmatic.com/rss2.xml	Dj @Z@S Podcast	Dj @Z@S		https://assets.podomatic.net/ts/0e/2f/77/djazas/1400x1400_2618764.gif
2029	http://djdangerousdino.podOmatic.com/rss2.xml	Mix Factory With DJ Dangerous Dino	DJ dangerous Dino	Mixes Of Different Genres of Dance Music and Hip-Hop in the Club Scene.	https://assets.podomatic.net/ts/77/71/67/djdangerousdino/3000x3000_603930.jpg
1919	http://dj-lbr.backdoorpodcasts.com/index.xml	DJ LBR - THE OFFICIAL PODCAST	Dj LBR	DJ LBR est sans conteste l'un des meilleurs DJ de l'histoire du clubbing français. Vice-champion de France DMC en 1988, c'est cette même année que commence Radio Star. Puis suivront Radio Nova avec Cutkiller et East, Skyrock, NRJ et Radio FG. Membre fondateur du Double H, DJ LBR est le seul DJ de sa génération à avoir franchi les frontières et produit aux Etats-Unis. C'est en 1998 que DJ LBR signe sur le fameux label de Party Break Av8 record dont il devient le principal artiste avec Crooklyn Clan et Fatman Scoop. Ses collaborations sont nombreuses aux côtés de Nappy Paco, Big Ali, Fatman Scoop, Stik.E, Cutkiller, Dax Rider, Anaklein, Big Nito, Ls, Hasheem... Découvrez vite son podcast !	http://dj-lbr.backdoorpodcasts.com/uploads/items/dj-lbr/lbr-the-official-podcast.jpg
1920	http://dj-lesty.backdoorpodcasts.com/index.xml	LESTY - LE PODCAST OFFICIEL	Lesty	Certains destins se dessinent tôt. Celui de Lesty en fait partie, ce jeune DJ dont la réputation n'est désormais plus à faire.Séduisant un public large mais non moins exigeant, il s'est imposécomme l'un des jeunes leaders du D-Jing Français.Aujourd'hui considéré comme une valeur sûre de la capitale, il s'exporte partout en France, jusqu'à la Reunion.Il est régulièrement sollicité en Europe, et attire l'attention de la scène internationale en se produisant sur de nombreux continent(Afrique/Amérique/Asie).\nArtiste accompli, ses podcasts connaissent un succès incontestable, et font de lui une référence en matière de podcasts.Lesty est l'artiste à suivre, laissez vous guider par sa musique.\n___________________\nCertain destinities emerge early in life such as Lesty’s, this young DJ whose reputation is now well established. Seducing a broad audience but no less demanding, he has become one of the young leaders of French D-Jing. Now considered as a safe bet in the capital, he’s exported all over France tothe Reunion. He is regularly contacted throughout Europe and draws theattention at international level by performing on many continents (Africa /America / Asia). ... Being an accomplished artist, his podcasts are anundeniable success making him a reference for podcasts. Lesty is the artistto follow, let yourself be guided by his music.	http://dj-lesty.backdoorpodcasts.com/uploads/items/dj-lesty/lesty-le-podcast-officiel.jpg
1921	http://dj-locksmith.podOmatic.com/rss2.xml	Rudimental	Rudimental	Welcome to the world of Rudimental.	https://assets.podomatic.net/ts/b5/c9/f9/dj-locksmith/1400x1400_13814117.jpg
1922	http://dj-luke-allen.podomatic.com/rss2.xml	DJ LUKE ALLEN	Luke Allen	Luke realized early on how music shapes emotion and emotion shapes music. Being aware of the continuous nonverbal exchange occurring between the DJ and the audience, he avidly seeks out music that has great energy from start to finish and that will tap into the emotions of the audience. Aware of both the lyrical as well as the musical content of his music, DJ Luke Allen brings this emotion to the dance floor.  It is best explained that Luke doesn’t just hear music, but feels it.\nLuke pays careful attention to his song selection and flow, creating a tailor made set for each individual performance.  Variety being the key to his trademark style, DJ Luke Allen believes in tapping into all musical genres to make a complete journey; constantly moving his listener along with subtle forward motion.  Within the journey the audience can expect to hear selections that reflect House, Progressive, Trance, Tribal, Pop, and Latin; all catering to the mood that both the DJ and the audience create.  \nHolding dual weekly residencies in the 2nd largest metropolitan area of the US and guest DJing in key markets and venues across the country; Luke stands ready to share his vision with the world.	https://assets.podomatic.net/ts/bc/d5/78/djlukeallen/3000x3000_7519501.jpg
1923	http://dj-maestro.backdoorpodcasts.com/index.xml	DJ MAESTRO - OFFICIAL PODCAST	Dj Maestro	Discover the universe of DJ MAESTRO. Subscribe and get a monthly updates of DJ MAESTRO mixes.\nThe best sounds of club musics of moment : HIP HOP/RNB MIX, ELECTRO-HOUSE MIX,  or RAGGA/DANCEHALL MIX\nAs well as mixes which return you to the Old school vibz.\nMore information on www.djmaestro.fr\nContact booking :Tony Tozikalprod : +33 6 65 73 84 38 E-mail : djmaestrobooking@gmail.com	http://dj-maestro.backdoorpodcasts.com/uploads/items/dj-maestro/dj-maestro-simply-club-podcast.jpg
1924	http://dj-maze.backdoorpodcasts.com/index.xml	DJ MAZE Audio & Video Podcast	Dj Maze	Dj Maze vous ouvre les portes de son quotidien. Dj - Compositeurs - Réalisateur - Patron de Amazing studio, P2S Records. Ce Dj Hors du commun qui a déjà a son actif + de 1 million de disque vendue, des doubles disques d' or, des triples ... des soirées a travers le monde, des show radio sur Nrj, Fun Radio ... des 1er partie a Paris Bercy, au Zénith .... et j' en passe .... \nDj Maze vous donnes désormais rendez vous dans sa web-série. Pour tout savoir, tout comprendre ...\nBon visionnage et laisse ton comm ça fait tjrs plaisirs Merci !\nhttps://www.facebook.com/DJMAZEOFFICIEL\nhttp://instagram.com/djmazeofficial\nhttps://twitter.com/DJMAZEOFFICIAL\nhttp://www.youtube.com/djmazetv\nhttps://soundcloud.com/deejay-maze-1\nhttps://itunes.apple.com/fr/podcast/dj-maze-audio-video-podcast/id299630046?mt=2	http://dj-maze.backdoorpodcasts.com/uploads/items/dj-maze/dj-maze-audio-video-podcast.jpg
1925	http://dj-mouss.backdoorpodcasts.com/index.xml	DJ MOUSS - OFFICIAL PODCAST	Dj Mouss	DJ MOUSS, The "Official World's Finest Clubs DJ",\nCheck Out " DJ MOUSS MEDIA KIT 2013 "\nDJ MOUSS, One of the most famous DJ’s in the world, has a very impressive biography.He is known at an international level thanks to his original career;his sets are wanted in the most beautiful VIP Clubs in all of our capitals worldwide, Paris, Moscow, Budapest, Stockholm, Marrakech, Zurich, Montreal or Los Angeles. He has managed to gather, with fluency, excellence, the mastering of scratch and his art of putting fire to the dance floors, his sole purpose is satisfying his public will. He only appears when prestigious events are on the way, such as Fatman Scoop French tour, the NRJ Music Awards or the Usher’s concert, which makes him unquestionably a true turntable star. DJ Mouss strengh stays in his ability to mix with success, when the other Hip Hop DJ's are not expected to be. Here you are some examples of his performances, just to mention them: During the last Technoparade in Paris, Mouss succeeded to make 80,000 techno music fans dance on Hip Hop, Electro & Dubstep music! Mouss was the first Hip Hop DJ resident of The Queen (the mythical house music club on the Champs Elysées, Paris) for more than 2 years. DJ Mouss is always on the avant-garde and advanced on the musical tendances. He is respected by everyone for his innate ability to inflame the dancefloors, and also for excelling in all the deejaying disciplines.\n\nDJ MOUSS是世界最好的俱乐部世界会所之旅里的专业DJ，他有令人印象深刻的非凡经历。\n从事DJ工作多年，DJ Mouss已享有国际水准。世界各地最好的贵宾会所都会希望他的加入。这些地方包括：巴黎，莫斯科，布达佩斯，迪拜，马拉喀什，香港，新加坡，蒙特利尔或是洛杉矶。\n作为成功的DJ，他控制的音乐流畅，优质，让舞池狂热似火。\n他致力于满足大众的意愿。但只现身于声望高的活动典礼中，如Fatman Scoop 法国之旅、法国NRJ音乐典礼以及the Usher 的演唱会。这些典礼毫无疑问地让DJ Mouss成为打碟唱盘前的一颗闪亮的明星。\nDJ MOUSS MEDIA KIT 2013\n\n\nF : https://www.facebook.com/World.DjMouss\nT : https://twitter.com/DJMouss\nE : melany@djmouss.com	http://dj-mouss.backdoorpodcasts.com/uploads/items/dj-mouss/dj-mouss-official-podcast.jpg
1926	http://dj-psychs.podOmatic.com/rss2.xml	Dj Psychs	Dj Psychs	Hot Up Beat Salsa, Merengue, Reggaeton, Merengue Hip Hop, Techno, Dance a little Bit of Everything Going on in here. Visit our website at 5stardjz.com\n\n\n\n\n My Podcast Alley feed!\n{pca-a4df2f36741c564cd6d3566f89626c68} \n\n  Podshow PDN  {podshow-51af46fc60c82b94386ff2ad4598ce2e}	https://assets.podomatic.net/ts/ad/27/b8/dj-psychs/3000x3000_2025674.jpg
1927	http://dj-remy.podomatic.com/rss2.xml	R.E.M.Y aka Captain Ad-Hok Channel  - http://www.dj-remy.fr	R.E.M.Y	Tous les mois retrouvez nos dj's pour des mixs Industrial Hardcore, Dubstep et House Progressive !\n\nhttp://www.dj-remy.fr\n---\n\nEvery month meet our dj's for industrial, hardcore, dubstep, house and progressive mixes !\n\nhttp://www.dj-remy.fr/en/	https://assets.podomatic.net/ts/ca/0e/7f/remylenoir/3000x3000_5070837.jpg
1945	http://djadamcooper.podomatic.com/rss2.xml	Adam Cooper's Get House'd Podcast	Adam Cooper	Select UK Radio host, International DJ and Music Producer Adam Cooper brings you weekly House and Progressive House mixes. Each mix is 1 hr of uplifting dance music. Perfect for house parties, gym workouts and every day listening anywhere and everywhere you can crank it up!\nwww.djadamcooper.com for more information.\nAlso follow Adam on facebook: http://www.facebook.com/adamcooperdj\nand Twitter: http://twitter.com/DJadamcooper\nand the DJ list: http://thedjlist.com/djs/ADAM_COOPER/	https://assets.podomatic.net/ts/56/2c/b0/adam2345/pro/3000x3000_11250473.jpg
1946	http://djadammatson.podomatic.com/rss2.xml	DJ Adam Matson Ark Bar Koh Samui Thailand	DJ Adam Matson - Ark Bar Beach Club Koh Samui Thailand		https://djadammatson.podomatic.com/images/default/D-3000.png
1947	http://djadrianrich.podomatic.com/rss2.xml	Adrian Rich Presents: Sexy House Beats	Adrian Rich	Adrian Rich Presents: Sexy House Beats	https://assets.podomatic.net/ts/ce/58/d4/djadrianrich/3000x3000_10883854.jpg
1929	http://dj-sbk.backdoorpodcasts.com/index.xml	Dj Shuba-K // YOUR MUSIC DEALER	Dj SHUBA K	DJ SHUBA-K // MAKE PEOPLE HAPPY SINCE 2002\nFort de 18 Années d’expérience. Shuba K est un Dj du sud de la France basé à Marseille, se produisant partout en France et dans le monde, afin de prêcher la bonne musique - La musique est sa religion -\nSes influences et références musicales sont très riches, allant des années 60 à nos jours, des musiques latines à celles d’Afrique, du Rock au Jazz, de la House à la chanson Française... Mais ce qu’il préfère ce sont les sons qui groovent : la Soul, le Funk, le Hip Hop. Vous l’aurez compris il est à l’aise dans tous les styles et devant tous les publics.\nSes show lives sont chaleureux, festif & So Happy !! \nVous l’avez sûrement vu lors des avants premières d’artistes internationaux comme Sean Paul, Bob Sinclar, The Avener ou encore Craig David par deux fois. Il est encore plus probable que vous l’ayez écouté lors de ses passages sur Skyrock, Mouv’ Radio, OKLM Radio, ou sur son podcast “Your Music Dealer” disponible sur internet, cumulant + de 7 Millions d’écoutes partout dans le monde.\nWWW.DJSHUBAK.COM	http://dj-sbk.backdoorpodcasts.com/uploads/items/dj-sbk/dj-shuba-k-your-music-dealer.jpg
1930	http://dj-serom-bounce-mix.backdoorpodcasts.com/index.xml	DJ SEROM : THE BOUNCE MIX PODCAST	djserom	Dear music lovers, turn the volume up !!! This is your favorite mixshow !!!\n>> THE BOUNCEMIX <<\nIt's going down each and every week with nothing but the best DJ : DJ SEROM !!!\nStraight up from France, DJ SEROM is taking you back to the finest Urban and Mash-Up music !!!\nKEEP YOU BOUNCIN' SINCE 2007	http://dj-serom-bounce-mix.backdoorpodcasts.com/uploads/items/dj-serom-bounce-mix/dj-serom-the-bounce-mix-podcast.png
1931	http://dj-shotgun-wound.podOmatic.com/rss2.xml	dj-shotgun-wound's Podcast	dj-shotgun-wound	Music is my passion....\n\nRecently made the change to the digital world with a Pioneer DDJ1000 so hopefully more mixes to come.\n\nMy main genres are Deep House/ Deep Tech although my roots are from early Trance and also like Liquid Drum and Bass.\n\nNot really into commercial music although i suppose some is good (only some in small doses)	https://assets.podomatic.net/ts/20/0c/6f/dj-shotgun-wound/pro/3000x3000_13555127.jpg
1932	http://dj-snake.backdoorpodcasts.com/index.xml	DJ SNAKE	Dj Snake	Dj Snake from Paris, France	http://dj-snake.backdoorpodcasts.com/uploads/items/dj-snake/dj-snake.jpg
1933	http://dj-thereflector.podomatic.com/rss2.xml	DJ  TheReflector	DJ  TheReflector	Ident : TheReflector Dj & Produser\nLocation : Hamburg-City\nAge : 40\nGender : male\n\nFacts :\n\n- listens to electronic music now for about 15 years\n- learned to play percussion instruments and using notation for about 2 years\n- started Dj-Mixing in 1996\n- owned first computer and started using Magix Music Maker in 1998\n- first DJ-Gigs on friendŽs parties\n- started mixing Terchno sounds\n- first steps with Fruityloops in 1999\n- first public DJ-Gig at the camping-field of Air beat 2003\n\n- created his first really good works in 2005\n- hard practise in sound-editing, effects and mastering in 2005\n- first steps with Fruityloops in 2004\n\n\n- first payed DJ-Gig in a\n discothek in               Germany                     Braunschweig(Toxic Club) \n      in 2006\ndiscothek in \n  Germany Elmshorn (Gleiss4)\n      in 2007\ndiscothek in \n  Germany Hamburg(Ursprung)\n      in 2008\ndiscothek in \n  Germany Braunschweig(Toxic Club) in 2008\n------------------------------------------\n \nhard_disc_version_1.0_mixed_by_lenny_dee_ - MyVideo \n----------------------------------\nPER ITALIANO:\n\nIdent: thereflector DJ & produser/DJ con due visione di Hardstyle DJ Team----- luogo: Amburgo -luce rossa area -- età: 40 -- sesso: maschi -- fatti:-ascolta musica elettronica ora per circa quindici anni-imparato a suonare strumenti a percussione e usando la notazione musicale per circa due anni-iniziato DJ-mixing in 2001-Proprietà primo computer e ha cominciato ad usare magix Music maker in 2002-primo DJ-concerti su amici parti-iniziato miscelazione Techno suoni-Primi passi con fruityloops in 2002-primo pubblico DJ- -primo pubblico DJ-concerto presso il Camping-CAMPO D'ARIA Beat 2003 -Crea il suo primo veramente buone opere in 2005-difficile esercitare in audio-editing, effetti e Mastering in 2005-primo svolto DJ-Gig in una discoteca in Braunschweig, Germania (tossico Club) in 2006 on www.uptrax.de in 2008--- www.myspace.com/thereflectordjk-- TheReflector_DJK@freak-mail.com-- www.djmixes.com/TheReflector_DJ\n--And please, ANY and ALL feedback is welcome. Any tips would help too. Thanks and enjoy (I hope)\n\ncheers	https://assets.podomatic.net/ts/f1/b3/cd/dj-thereflector/3000x3000_1922978.gif
1934	http://dj-vice.podomatic.com/rss2.xml	VICE AIRWAVES LIVE	VICE	VICE AIRWAVES WITH VICE	https://assets.podomatic.net/ts/cf/0f/e6/djvice/pro/3000x3000_12994166.jpg
1935	http://dj-warpin.podOmatic.com/rss2.xml	DJ  Warpin's Podcast	DJ  Warpin		https://dj-warpin.podomatic.com/images/default/podcast-3-3000.png
1936	http://dj-wid.backdoorpodcasts.com/index.xml	Dj Wid - Come with Me Podcast	Dj Wid	Bienvenue dans mon podcast, retrouvez y tous mes mixes et exclus !! Plus d'infos sur ma page facebook : http://www.facebook.com/Dj.Wid	http://dj-wid.backdoorpodcasts.com/uploads/items/dj-wid/dj-wid-come-with-me-podcast.jpg
1937	http://dj.floy.free.fr/djfloyparadisegaragepodcast.xml	DJ Floy  - Paradise Garage Radio Show	DJ Floy	Weekly mix show about House Music by Floy , French House Music producer (Cabana/Soulheat/Abicah Soul) .. https://www.facebook.com/floy.mestre/	http://dj.floy.free.fr/Photo%2002-06-11%2018%2052%2022.jpg
1939	http://dj2xtreme.podOmatic.com/rss2.xml	Dj 2xtreme's Podcast	Dj 2xtreme	Chicago born and raised Dj 2xtreme brings you the latest and hottest underground tech/minimal/deep/indie dance/\nnu-disco/house/progressive/electro/dubstep found in Chicago and from around the globe. Whether you like his well established "Late Night Intoxication" series of Tech/Minimal/Progressive that he is so well known for, his series "FUKURFAAAS" full of heart pounding sweat dripping Electro/Dubstep/Bass music, LNI DEEP loaded with the newest Deep House/Indie Dance/Nu-Disco, or his Newest Series LNI This Is House Music which will give you a ton of straight Chicago House Music you will be sure to find something that will get your body, mind, and soul moving! So get up out of your seat and get ready to get INTOXICATED by the sounds of Dj 2xtreme!	https://assets.podomatic.net/ts/e6/4f/51/dj2xtreme/3000x3000_3955783.jpg
1940	http://dj5erious.podbean.com/feed/	5ERIOUSLY HOUSE	5ERIOUS	Monthly podcast featuring a rotation of 5ERIOUS’ favourite genres, including the latest tracks and unreleased music. http://www.dj5erious.co.uk	https://pbcdn1.podbean.com/imglogo/image-logo/292229/PodcastArtwork_v3.jpg
1941	http://dj5ive.podOmatic.com/rss2.xml	dj 5ive, NYC	dj 5ive	Twitter:       @dj5iveNYC\nFacebook:  www.facebook.com/dj5ive\nInstagram: www.instagram.com/smw.nyc\nWebsite:     www.soundcloud.com/dj5ive	https://assets.podomatic.net/ts/77/7e/41/dj5ive/pro/3000x3000_8884122.jpg
1942	http://dj811.podomatic.com/rss2.xml	dj811	DJ811		https://assets.podomatic.net/ts/42/b9/b2/deagler11/3000x3000_9150218.jpg
1943	http://djabel-mia.podomatic.com/rss2.xml	ABEL AGUILERA'S Podcast Page	ABEL AGUILERA	Grammy Award Nominee Dj/Producer, House, Vocal house, Tribal House, Techno, Tech House, Progressive House, Electronica, Disco, and even Chill out !	https://assets.podomatic.net/ts/93/e4/f5/mixdis/pro/3000x3000_6105285.jpg
1944	http://djacraig.podomatic.com/rss2.xml	DJ ACraig Podcasts	DJ ACraig		https://assets.podomatic.net/ts/89/69/05/events8599/1400x1400_10826861.jpg
1948	http://djagonline.podomatic.com/rss2.xml	DJ AG Podcast	Ashley Gordon	DJ AG is an up and coming DJ from London. Check out DJ AG's fresh mixes!!!\nFor bookings send an email to info@djag.co.uk or call 07834274678\n@djagonline	https://assets.podomatic.net/ts/cb/d2/c3/info43742/3000x3000_7970729.jpg
1949	http://djajmora.podOmatic.com/rss2.xml	AJ Mora's Podcast	AJ Mora		https://djajmora.podomatic.com/images/default/podcast-1-1400.png
1952	http://djallure32.podomatic.com/rss2.xml	Tomas Canoti: The Sessions Podcast	Tomas Canoti	Tomas Canoti: Featuring The IMMERSION Sessions, Levitation & All new: Elusion Sessions: Deep and Progressive House. \n---Due to issues within my podcast recordings i can no longer host my older mixes. (at this time)\nI am still very vested in creating Pride and club dance mixes. Hopefully i can return sometime to creating them again.\nTake Care Everyone	https://assets.podomatic.net/ts/6c/57/90/djallure32/pro/3000x3000_14871753.jpg
1953	http://djalroche.podomatic.com/rss2.xml	dj al roche london house	Al Roche		https://djalroche.podomatic.com/images/default/podcast-2-3000.png
1954	http://djamoofficial.podomatic.com/rss2.xml	DJ a.MØ	Dj a.MØ		https://assets.podomatic.net/ts/c9/73/12/djamo83622/3000x3000_15126685.jpg
1955	http://djandrea.podomatic.com/rss2.xml	DJ Andrea's Dance Factory!	DJ Andrea	DJ Andrea brings you high energy dance grooves, Classic hits, and Vocal House mix compilation series, including a few essential DJ ANDREA “ Megamixes”. All of these mixes are guaranteed to get your pulse pounding and your feet moving with positive energy! These series are great to download if you’re throwing a house party, BBQ, working out, or taking a long drive!  It is like bringing the club to you without paying a cover charge!  Please share this page with any club hopping friends you may know who'd enjoy listening to this.  I would also LOVE your feedback !!	https://djandrea.podomatic.com/images/default/podcast-1-3000.png
1956	http://djandroid.podomatic.com/rss2.xml	Joshua Eisenhauer's aka djandroid former Podcast	Joshua Eisenhauer djandroid	Soundcloud djandroid joshua eisenhauer	https://djandroid.podomatic.com/images/default/podcast-1-1400.png
1957	http://djandyb.podomatic.com/rss2.xml	Andy B's Podcast	andyb		https://assets.podomatic.net/ts/4a/6c/25/andybradley20/3000x3000_7300571.jpg
1959	http://djandyhsmixes.podomatic.com/rss2.xml	DJ Andy H's Podcast	DJ Andy H		https://djandyhsmixes.podomatic.com/images/default/podcast-3-1400.png
1960	http://djanemissgul.djpod.fr/podcast.xml	DJ MISS GUL	DJ MISS GUL	DJ MISS GUL débute sa carrière dans le Djing en 2008 et se fait très vite un nom sur la scène Electronique.\n\nLors de ses prestations, son professionnalisme, son look chic et glamour et ne laissent aucun dancefloor indifférent,\nelle séduit rapidement les clubs de part son éclectisme musical qui deviendra la clé de son succès pour jouer dans de nombreux pays et festivals :\n\nEn FRANCE : Paris, Metz, Bordeaux, Lille, Strasbourg, Dijon, Lyon ...\n\nEt aussi à l'international : ESPAGNE, ILE MAURICE, INDE, PORTUGAL, LUXEMBOURG, ALGERIE, LIBAN, GUADELOUPE, JORDANIE, SYRIE, TURQUIE, MAROC, TUNISIE, BELGIQUE, EGYPTE dans des événements prestigieux tels que\nle Sea Lounge à Monaco pour la marque "Cartier" ou encore dans des clubs très réputés comme le "SPACE" Sharm El Sheikh ou le PACHA Marrakech.\n\nElle a également déjà eu la chance de se produire auprès de DJs producteurs mondialement reconnus à savoir : Joachim Garraud, Green Velvet, Da Fresh, Gregor Salto, Big Ali, Sebastien Benett, Antoine Clamaran.\n\nRécemment élue vice championne de France au Queen Club Paris lors du grand concours international SHE CAN DJ avec NRJ et EMI\nVous avez également pu l'apercevoir sur M6 Music, M6 Club ainsi que W9.\nElle a fais aussi plusieurs apparitions et interviews pour des magazines tels que : Only For DJ's (France), Noite (Portugal), Be 2 Night (Belgique), Com'On Marrakech (Maroc) et bien d'autres ...\n\nAvec une notoriété grandissante, elle fait d'ores et déjà partie des meilleures Djettes de sa catégorie et ses ambitions sont loin de s'arrêter là, d'autres collaborations et projets sont à venir mais surprise ...\n\nEn attendant la belle enchaîne les dates et continue d'agiter les dancefloors du monde entier.	https://i1-static.djpod.com/podcasts/djanemissgul/e9e315_1400x1400.jpg
1962	http://djaramis.podOmatic.com/rss2.xml	DJ Aramis Trance Global Podcast	aramis hernandez	For the last three years Aramis has presented his take on the trance scene through his Trance Sessions show on the industry-leading stations.Trance Sessions & Nations presents a crystal-clear monthly snapshot of Aramis’s in-and-out of club sound, exploring the outer reaches of electronic music.	https://assets.podomatic.net/ts/24/17/cd/djaramis/pro/3000x3000_13243012.jpg
1963	http://djartiev.podOmatic.com/rss2.xml	Dj Artie V's podcast	Dj Artie V	WRITERS USE WORDS, PAINTERS USE COLORS, DANCERS USE THEIR BODY..... WE DJ'S USE MUSIC AS OUR MEDIUM. WE ARE MUSIC ARCHEOLOGISTS TELLIN A STORY A MYSTICAL VOYAGE FOR EVERYONE TO SHARE	https://djartiev.podomatic.com/images/default/podcast-1-1400.png
1964	http://djasb.podomatic.com/rss2.xml	D-Jas B's Podcast	D-Jas B	Sweet Nothing (Tiesto Radio Edit) - Calvin Harris Feat. Florence Welch\nFeel The Love (SAMPLED) - Rudimental\nDiamond (Primacy Funk Remix) - Rihanna\nFree (Maurizio Gubellini & Matteo Sala Mix) - George Acosta\nSpectrum (Say My Name) (Fred Remix) - Florence And The Machine\nWide Awake (Jump Smokers Radio Edit) - Katy Perry\nSkyfall (Cosmic Dawn & Andy Reese Remix) - Adele	https://assets.podomatic.net/ts/68/09/be/djasb/3000x3000_7669487.jpg
1965	http://djaycj.podomatic.com/rss2.xml	DJ CJ Podcast	Clay Jacobs	Continuous mixes with iTunes visualizer video effects.	https://assets.podomatic.net/ts/96/e3/2b/clayjacobs2451154/3000x3000_7482863.png
1966	http://djayeena.podomatic.com/rss2.xml	DJ AYEENA PODCAST	Ayeen Azucena		https://assets.podomatic.net/ts/63/8d/15/djmarkcena/3000x3000_7586477.jpg
1967	http://djaym.podOmatic.com/rss2.xml	DJAYM's Podcast	DJAYM	DJAYM, M to his friends, started his journey with music as a dancer while still at school. Dance and performance, with additional elements of gymnastics and choreography led to him teaching dance with a strong artistic method that expressed his ambition to combine excellent dance with good and happy music, unique beats and instrumentals creating new moves for dance to speak through the music. \n As audio visual manager, he created Lights & Sounds that meshed with the atmosphere at Neo Bar in Bangkok where he become a DJ in 2005. He enthusiastically filled residencies in Bangkok and Cambodia. He was guest DJ at many international clubs including Club Dragon-San Francisco, Arty Farty-Tokyo, Hula's-Honolulu, Volume-Hong Kong with requests to return again. \nThe COME DANZ with DJ M compilations started with a recurring dance music show on Tamo Radio, Radio 365 in Honolulu\nHe was invited to play for the first ever JING PRIDE in Beijing in 2010; he also played for Shanghai Pride in 2010. He returned to Bejing for JING PRIDE 2011.\nHe is a Diplomate in Electronic Music Production, SAE Institute, Thailand in 2012\nAs DJ, producer and composer of The PROJECT LIFE, he is creating a musical biography that expresses the artistry developed from his experiences of dance, show, performance, that is found in his Progressive-House-Electronic and other music styles, that speaks to all and always brings everyone together around the party.  \nTo see a happy dancing audience is Gold for DJAYM!\nWeb : www.djaym.com\nEmail : djaymsobe@yahoo.com\nDJAYM from Thailand recently located @ Miami Beach, USA	https://assets.podomatic.net/ts/3e/c5/26/djaym/3000x3000_11804539.jpg
1968	http://djayteekane.podomatic.com/rss2.xml	Aytee Kane / OTTO MANN - Groovy Progressive Tribal Tech Minimal Deep House Belgian Afterhours Retro Acid Nu Disco	Aytee Kane / OTTO MANN	Huge Worldwide Succes on ITunes and podomatic.  Already 3 years at ~What's Hot/Trending~ on iTunes! Between big names like Eric Prydz, Roger Sanchez, Mark Knight, Thomas Gold, Fedde Le Grand, Afrojack and many more...  \nSo, Not another podcast and not just music, Best classics & future classics. 'Twist depending on my life experiences and personal growth. You can call them sexy, full of love and emotionally loaded... '\n\nhttps://www.facebook.com/djayteekane\nhttps://www.mixcloud.com/AyteeKane/\nhttp://djayteekane.podomatic.com/\nAytee Kane @ iTunes\nhttps://itunes.apple.com/be/podcast/aytee-kane-groovy-progressive/id457506533?l=nl&mt=2\n\nThe very busy Toni&Guy Style Director Aytekin Cesmeli / " AYTEE KANE " never intended to be a performing dj.. After a live on Radio Fg performance followed by his own FG Radioshow & the succes of his podcasts, bookings followed. His second booking was in the legendary club La Rocca, where he used to party with friends almost each sunday.. His life has changed forever.. while working at festivals like Daydream festival, Extrema outdoor Belgium, Sunrise Festival, Tomorrowland , Fi:HP, Sensation White, Carré and shoots and magazines as Stylist he started to mix in Clubs & Bars in the city's Antwerp , Brussels , Gent, Mons and around and Amsterdam. Clubs  like Club D-Lux (Antwerp) , Nation Club (Brussels), La Rocca (Lier), Residency at Club Random (Antwerp) , Residency at Stammbar (Brussels) & Residency at Dolores Bar (Brussels) , Residency at Shoushou's Gay Party (Bernissart,Mons) ,  People Bar (Brussels) , The Boots (Antwerp) , Cocteau Gentse Feesten festival (Gent) , Club Adonis (Drongen, Gent), La Moon (Brussels) , Tafeltje Rond (Antwerp),  Le Baroque (Brussels) , Revelation after-parties at Stammbar, La Demence after-parties at Macho , Revelation after-parties at Stammbar,  Private parties in Brussels, booked for club Roque Amsterdam.. Private (Amsterdam), Double bookings, from disco to disco, city to city he's growing day by day... \nThis is only the beginning... \nNow it is time for Producing because Aytee Kane received his first remix request this year... \nand again he will be working on all the Belgian festivals.. and Clubs \nWhile mixin' and taking his crowd with him on a trip...\n\nfor Bookings : aytekin77@hotmail.com / +32483080412	https://assets.podomatic.net/ts/3f/81/ec/aytee-kane/3000x3000_11449005.jpg
1970	http://djb2.podomatic.com/rss2.xml	DJ BEN BAKER || PODCASTS AND LIVE SETS	DJ Ben Baker	DJ BEN BAKER PODCASTS AND LIVE SETS\n\nSUBSCRIBE to Ben Baker's podcast free on iTunes at: tinyurl.com/DJBenBakerItunes\n---------------------------------------------------------\nFOLLOW BEN BAKER … \nFacebook: www.facebook.com/djbenbaker\nTwitter: www.twitter.com/djbenbaker\nInstagram: www.Instagram.com/djbenbaker\n----------------------------------------------------------\nFor Booking Information : \nEmail: djbenbaker@icloud.com	https://assets.podomatic.net/ts/07/ca/43/benbaker58819/pro/3000x3000_11568105.jpg
1971	http://djbabymarquez.podomatic.com/rss2.xml	BL | Biagio Lana	Biagio Lana		https://assets.podomatic.net/ts/19/53/ea/cuba537/1400x1400_5334579.jpg
1972	http://djballistic-ec.podomatic.com/rss2.xml	DJ Ballistic Official Podcasts	DJ Ballistic	DJ Ballistic's part of Entertainment Cartel	https://assets.podomatic.net/ts/d2/ba/bd/djballistic-ec/3000x3000_6719844.jpg
1974	http://djbene.podspot.de/rss	Dj PLAY WITH HEART - PODCAST	Benedikt Bauer	Is a free podcast from Dj PLAY WITH HEART from Leipzig. Listen to fresh new Tech & Deep House tunes mixed by Tía Buena & BENEdikt and some friends from Dj PLAY WITH HEART Find us on Facebook and twitter: (DjPlayWithHeart, Tia Buena, djbene) Thanks to those that comment on the podcast. Your feedback is important. It's so easy because we all understand the language of house music - http://www.djplaywithheart.com	\N
1975	http://djbenesia.podomatic.com/rss2.xml	iDance the official dance broadcast	Benesia	iTunes - iDance/ Benesia (subscribe today!)\nEmail - cdjben@yahoo.com.sg	https://assets.podomatic.net/ts/42/36/ba/cdjben13585/3000x3000_3699822.jpg
1976	http://djbennybass.podOmatic.com/rss2.xml	Benny Bass' Podcast	Benny Bass		https://assets.podomatic.net/ts/fa/e6/55/djbennybass/3000x3000_2171198.jpg
1977	http://djbensims.podomatic.com/rss2.xml	BEN SIMS presents..FUNK YOU!	ben sims	This is my new monthly mix show/podcast, a 2 hr journey thru upfront and classic techno, house and machine funk.\nI'm hoping to get the show syndicated as much as possible, at present House FM in London will be adding it to their timetable, as will a soft porn TV channel in Slovenia (that's one for the C.V) but i'm definitely looking for more, so if you are a radio station (web or FM) please get in touch.\nThe show is mixed using the 'Bridge', the program that links Serato and Ableton, which is something i'm having fun experimenting with right now, at the moment just in the studio but i'll be giving it a go at the machine launch party in London on Feb 25th (www.machinelondon.com)\nAnyways, hope you like it.\nBS	https://djbensims.podomatic.com/images/default/podcast-3-3000.png
1978	http://djbigdirty.libsyn.com/rss	dj bigdirty's: night club musical	dj bigdirty	Welcome to the monthly Vocal Trance mixshow. I like to keep my mixes listener friendly, therefore I use a lot of vocal tracks (especially with trance).  I am a current resident DJ at Trinity in the heart of Boston where you can catch me every other Saturday night. I've also had residencies in the San Fran Bay area in the late 90's. I love the ethereal sound of trance music. I try to infuse a lot of this in my cd's while still managing to have massive floor fillers being a part of the mix also. I'm heavily influenced by Tiesto's In Search of Sunrise days, Andy Moor, Myon and Shane 54, Kaskade, Above & Beyond, Tydi and the Cocteau Twins. I'll play/mix any style of music, I'm not really trapped into just one. I prefer trance, vocal trance, prog-house, trip hop and chillout. Basically I just love music and putting it all together for that 80 minute rush. Every mix I make I hope it tells a story or I have a story about it. My high is a crowded dancefloor, happy faces or you smiling while listening to the mix.  For the latest in vocal trance and to join the new Night Club Musical Facebook webpage go to https://www.facebook.com/nightclubmusical	https://ssl-static.libsyn.com/p/assets/9/2/c/a/92cabc56fded7279/DJ_BIGDIRTY_ZAKIM.jpg
1979	http://djbigoz.podomatic.com/rss2.xml	Sound of Oz 2012	Omar Kuwatly	A weekly podcast for the hottest house sets that you can indulge yourself in each weekend. Sound of Oz. Quality house music for those who appreciate good music, brought to you straight from dubai	https://djbigoz.podomatic.com/images/default/podcast-1-3000.png
1980	http://djbillelcientifico.podomatic.com/rss2.xml	el100tifico	El100tifico	Deejay/Producer around the world, making good music, mixes and remixes for the whole community addicted to the good musically speaking.	https://assets.podomatic.net/ts/0b/53/39/cambastyles/3000x3000_13134771.jpg
1981	http://djbimshire.podomatic.com/rss2.xml	DJ BIMSHIRE	DJ BIMSHIRE	Born in Barbados… raised in DC, Dj Bimshire is one of the Nation's Capital most versatile djs. Known for his smooth mixes and high energy, this rising star has carved his way into the minds, hearts and EARS of party-goers in the DMV.\n\nBim, as he is affectionately known by his peers, followers & dj counterparts, started his professional dj career at the young age of 15, with Muzik Nashun Sound in 2000.\n\nNow almost 15 years later, Bim's dj career extends over all the major nightclubs, promoters and major events in the DC metropolitan area, working with artistes like Wale, Michael Blackman, Blac Chyna, Lloyd Banks, Jadakiss, Elephant Man, Baby Cham, Konshens, Capleton, Shal Marshal, along with other local celebrities like Fat Trel, Phil Ade, Raheem DeVaughn and Phil Da Future.\n\nFOR BOOKING DJBIMSHIREBOOKINGS@GMAIL.COM PLACE DJ IN THE SUBJECT LINE	https://assets.podomatic.net/ts/16/14/6c/djbimshire/3000x3000_8933051.jpg
1982	http://djbl3nd.libsyn.com/rss	DJ BL3ND Loko Radio	DJ BL3ND	DJ BL3ND brings you the hottest music in EDM, feat. exclusive tracks from some of the biggest DJs and Producers in the game.	https://ssl-static.libsyn.com/p/assets/a/c/2/7/ac27b15ae27cebb3/LokoRadio_Itunes_Cover.jpg
1983	http://djblackrabbit.podOmatic.com/rss2.xml	Rabbit Radio	DJ Black Rabbit	In this world of stagnant music and uncaring DJs welcome to the light at the end of the tunnel. Rabbit Radio is the place to find both the hottest new music and of course the best of yesterday mixed into a delightful mix. I will feature music from pop to jazz to hip-hop and everything in between. So sit back, relax, and enjoy...	https://assets.podomatic.net/ts/76/da/44/djblackrabbit/3000x3000_2272730.jpg
1985	http://djbobbiejones.podomatic.com/rss2.xml	DJ Bobbie Jones' Podcast	DJ Bobbie Jones	Welcome to DJ Bobbie Jones - Master Mix Series. Introducing Bobbie Jones Praise Party and Club/House music experiences featuring inspirational speakers and the Klub Muzik Societi.  Designed to educate and motivate beyond the church and club walls, delivered through creative music of gospel, house, club, jazz, or simply good music.  IN-JOY;IN Peace.\n\nOpen Mind, Open Ears, Open Heart\ndjbobbiejones@gmail.com\nhttp://www.facebook.com/djbobbiejones	https://assets.podomatic.net/ts/65/27/e7/djbobbiejones/3000x3000-0x0+0+0_9607300.jpg
1986	http://djbobbyd.podomatic.com/rss2.xml	DJ Bobby D Groove Therapy	djbobbyd	DJ, Business Owner at Traffic Radio, dj agency, website development in Paralimni, Cyprus. I have been working as a Dj since 1985 and I'm from Bulgaria, but I already live in Cyprus. www.djbobbyd.org	https://assets.podomatic.net/ts/35/d9/76/djbobbyd/3000x3000_8012316.jpg
2076	http://djescape.podomatic.com/rss2.xml	DJ Escape's Podcast	DJ Escape		https://djescape.podomatic.com/images/default/D-3000.png
1988	http://djbolt.podomatic.com/rss2.xml	DJ Bolt's Podcast	DJ Bolt's High Energy Commercial Club mixes	If you enjoy my mixes, feel free to "like" or comment on them.\nAnd don't forget, you can subscribe to me directly through iTunes at\nhttps://itunes.apple.com/au/podcast/dj-bolts-podcast/id386304673\n\nYou can also contact me on facebook at \nhttps://www.facebook.com/richard.bolt.syd\n\nA regular at clubs and events around Sydney.\nSo if you're in town, come out and here me spin sometime :)	https://assets.podomatic.net/ts/dc/28/09/richard65194/pro/3000x3000_9457587.jpg
1990	http://djbruceobrien.podOmatic.com/rss2.xml	Classic Spiritual Gas Mixes	DJ Bruce O'Brien	Classic DJ Bruce O’Brien mixes from the period 2005 - 2012. This is Spiritual Gas so fill up your tank!	https://assets.podomatic.net/ts/16/f2/58/djbruceobrien/pro/3000x3000_13353811.jpg
1991	http://djbrucki.podomatic.com/rss2.xml	FewGenredio	DJ Brucki	FewGenredio - a fusion of multiple genres of music, providing something for everyone. DJ Brucki brings you podcasts capturing music from urban, electro, and caribbean genres.	https://djbrucki.podomatic.com/images/default/podcast-3-3000.png
1992	http://djbrunostrizic.podomatic.com/rss2.xml	SUBZERO Official Podcast	SUBZERO	Presenting the best in Deep, Future, Electro and Progressive House!\n\nEnjoy!\n\nMake sure you subscribe for new podcasts by SUBZERO.\n\nBe sure to LIKE my FACEBOOK \nhttp://www.facebook.com/subzer0dj	https://assets.podomatic.net/ts/0b/9c/08/djbrunostrizic/3000x3000_10646564.jpg
1993	http://djbryanreyes.podomatic.com/rss2.xml	DJ Bryan Reyes' Podcast	Bryan Reyes Official Podcast		https://assets.podomatic.net/ts/04/69/02/djbryanreyes/3000x3000_10124345.jpg
1994	http://djbullyb.podomatic.com/rss2.xml	DJ Bully B Essence of Soul Radio	Presenter DJ Bully B	Essenceofsoulmusic.com radio we are globally well known all over the world  for pushing independent, Soul, jazz, R&B, Neo Grooves and Gospel.	https://assets.podomatic.net/ts/d3/f5/9e/djbullyb/pro/3000x3000_14906889.jpg
1995	http://djbumper.podomatic.com/rss2.xml	DJ Bumper	DJ Bumper	DJ Bumper started spinning records in 1996.  Influenced by the "journey" of the Circuit sound in the mid nineties.  The LEGENDARY Buc, Darrin Arrowood, Lydia Prim, David Knapp, Michelle Miruski and St. Peter all influenced the direction of his music.	https://assets.podomatic.net/ts/95/b2/d8/studio5479199/3000x3000_4921714.jpg
1996	http://djbutterface.podOmatic.com/rss2.xml	DJ Butterface	DJ Butterface	www.djbutterface.com	https://djbutterface.podomatic.com/images/default/podcast-2-1400.png
1997	http://djbuttnaked.podOmatic.com/rss2.xml	Ives Audio Presents - Late Nights and Early Mornings ~ Dj Buttnaked	dj buttnaked	This is Late Nights and Early Mornings. A podcast by Dj's for music lovers. Please join your host Dj Buttnaked as he takes you on a musical journey each week with some of his dearest dj friends in the mix! There is no specific format we are just rocking what feels good.  Why now a podcast of all things? For a long time and now I am finally coming to grips that I just want to play what I want when I want how I want. I hope you enjoy it and can find a place in your own musical journey to fit the music that I play in your space. #love	https://assets.podomatic.net/ts/96/8a/9a/djbuttnaked/pro/3000x3000_14948872.jpg
1998	http://djc-bass.podOmatic.com/rss2.xml	C-Bass Podcast	Dj C-Bass		https://assets.podomatic.net/ts/67/b7/1a/djc-bass/1400x1400_3073848.jpg
1999	http://djcalbearboy.podomatic.com/rss2.xml	DJ CALBEARBOY'S PODCAST	Keith Escher(DJ CALBEARBOY)	Check out my other Podomatic page at: http://calbearboy.podomatic.com	https://assets.podomatic.net/ts/a8/fe/f4/kescher87/3000x3000_7678832.jpg
2000	http://djcam.podomatic.com/rss2.xml	DJ CAM Podcast	DJ CAM	A Podcast that supports GOOD MUSIC of all GENRES!!. http://www.facebook.com/DJCAM.TAMPA.FL	https://assets.podomatic.net/ts/d4/b3/bc/deejaycam6896/3000x3000_5114541.jpg
2001	http://djcarl.com/audio/podcast.urban.rss	DJ Carl© Hip Hop Music "Celebrity Mixtape" Podcast	DJ Carl©	"The genius behind the music!" You can workout to these hip hop or hip-hop mixes to help energize your soul - mentally, physically, and spirtually especially during the COVID-19 global pandemic. The mixtape is curated by award-winning, GRAMMY® member, music expert, DJ Carl©. Send donations via PayPal® - https://www.paypal.me/celebritydjcarl	https://www.djcarl.com/audio/images-music/dj-carl-urban-podcast-1400x1400.jpg
2002	http://djcarlosdali.podOmatic.com/rss2.xml	DJ Carlos Dali's Underground House Sets	DJ Carlos Dali	Creating surrealistic Sounds In Music\n....\n\nDali se desdibuja\ntirita su burbuja\nal descontar latidos\nDali se decolora\nporque esta lavadora\nno distingue tejidos\nel se da cuenta \ny asustado se lamenta\nlos genios no deben morir\nson mas de ochenta \nlos que curvan tu osamenta\n"Eungenio" Salvador Dali\n\nBigote rocococo\nde donde acaba el genio\na donde empieza el loco\nmirada deslumbrada\nde donde acaba el loco\na donde empieza el hada\nen tu cabeza se comprime la belleza\ncomo si fuese una olla expres\ny es el vapor que va saliendo por la pesa\nmagica luz en Cadaques\n(J.M. Cano)	https://djcarlosdali.podomatic.com/images/default/D-3000.png
2003	http://djcaseonline.net/v3/?feed=itunes	The #CASENATION Podcast	DJ CASE	Boston's Own, DJ CASE, bringing you nothing but the best in Open Format mixing!  \n\nFollow him on Twitter, @DJCASE, using hash tags #CASENation and #TheTakeover, and visit www.djcaseonline.net for more info!	http://djcaseonline.net/v3/wp-content/uploads/2013/05/DJCase_CasenationPodcast-300x298.jpg
2006	http://djchemics.podomatic.com/rss2.xml	Dj Chemics' Podcast	Dj Chemics		https://assets.podomatic.net/ts/61/8d/98/djchemics/3000x3000_2795639.jpg
2007	http://djchoiceonemd.podomatic.com/rss2.xml	DJ CHOICE-ONE MD MY MUSICAL MADNESS	DJ CHOICE-ONE MD	This is your home for any and everything CARNIVAL	https://djchoiceonemd.podomatic.com/images/default/podcast-2-3000.png
2008	http://djchrisfx.podomatic.com/rss2.xml	Tales From The Deep with DJ Chris Fx	Christopher Robbins (DJ Chris Fx)	Weekly Afro, Deep, and Soulful House Mixes by DJ Chris Fx\n\n  <img	https://assets.podomatic.net/ts/f5/ba/11/c-robbins67/3000x3000_8965177.jpg
2009	http://djchrisg73.podomatic.com/rss2.xml	DUBSTEP/ELECTRO PODCAST [Dj Chris g.]	dj chris g		https://assets.podomatic.net/ts/61/f8/80/djchrisg73/3000x3000_7407053.jpg
2010	http://djchristopherb.podomatic.com/rss2.xml	dj christopher b	dj christopher b	Want more from dj christopher b? \nCheck out www.djchristopherb.com\n\nOver the past 18 years, dj christopher b has had the pleasure of playing huge parties for some of the world's best venues and major outdoor events including Sydney Mardi Gras, Gay Days in Orlando, San Francisco Pride, and Flagging in the Park, reaching an ever-growing audience around the world. He also plays regularly in his hometown of San Francisco at Lookout, The EndUp, Public Works, and for REAL BAD special events REACH & RECOVERY. No matter where he’s spinning, Christopher loves to weave together retro tracks and current pop vocals, always infused with some disco and classic 90’s house, and with a primary objective to keep the crowd smiling and grooving. \n\nHappy listening!	https://assets.podomatic.net/ts/ee/13/22/cberini/pro/3000x3000_15092885.jpg
2011	http://djchubbyc.podomatic.com/rss2.xml	The Official Can of Spinage Show	DJ Chubby	My Can of Spinage shows, House music / EDM Mixes, and Uplifting Workout Series. All 1 hour continuously mixed DJ sets blended, crafted, mashed, and all CLEAN EDITS for safe listening by yours truly unless otherwise tagged.\n\nNow get up and dance, even if it's only in your head and in spirit for the love of dance music! \n\nMake sure to Follow me on all my other social media sites!\n\n• www.facebook.com/djchubbyc\n• www.twitter.com/djchubbyc\n• www.instagram.com/djchubbyc	https://assets.podomatic.net/ts/75/38/98/djchubbyc/3000x3000_11926215.jpg
2012	http://djclaudiare.libsyn.com/rss	Claudia Re - Sonic Cloud Radio	EAST RAGE MUSIC	Bring you electro, progressive, tech, and other dance music that's raw, wet and juicy, engorged with energy to stimulate your every palate...\n\nTune in for exclusive mixes by Claudia Re. \n\nFor more information please visit Claudia Re official fanpage : www.facebook.com/djclaudiare	https://ssl-static.libsyn.com/p/assets/a/4/b/8/a4b8f87472751b83/Claudia_Re_1400x1400405K.jpg
2013	http://djclo.podomatic.com/rss2.xml	DJ C-Lo's Podcast	DJ "C-Lo"	These are all original sets derived from late night sessions till the sun starts to come up...Stylez may change but the DJ stays the same...\n\nBringin' out the Soundz of the Underground	https://assets.podomatic.net/ts/c1/c6/92/mciesla2002/1400x1400_10805567.jpg
2015	http://djcookie.podOmatic.com/rss2.xml	DJ Cookie's podcast	Cookie	Facebook:http://www.facebook.com/ilovedjcookie\nOFFICIAL WEBSITE: http://www.dj-cookie.com/\nTWITTER: http://www.twitter.com/ilovedjcookie	https://assets.podomatic.net/ts/2f/13/ae/djcookie/3000x3000_10316306.jpg
2016	http://djcoolyc.podOmatic.com/rss2.xml	DJ Cooly C podcast	DJ Cooly  C	It's time to start dropping the hottest production, freshest remixes. If you really feeling what I'm bringing you kick in a small donation to help further the movement. Simply hit the paypal icon and donate what you can. Thanks and keep listening.\nhttp://djcoolyc.podOmatic.com/rss2.xml\nwww.djcoolyc.com	https://assets.podomatic.net/ts/68/72/06/djcoolyc/3000x3000_8893100.jpg
2017	http://djcosmo.podOmatic.com/rss2.xml	DJ COSMO | COSMOLOGY PODCAST	DJ COSMO	Starting in 2006 "Cosmology Podcast" is being monthly aired worldwide. Thank you for listening to my Podcast. As it turns out, there are a lot of you out there :)\nEnjoy my worldwide radio show or tune into "Cosmology" live: Every Friday 18:00-19:00 on www.safariradio.gr,all Thursday 3:00 pm (GMT) on www.Puresound.fm, all Sunday 5:00 pm (GMT3) on www.trance.cl / Chile, 2:00 pm (EST) Mexico, 6:00 pm Argentina, 8:00 pm (UTC,GMT) U.K, 9:00 pm (CET) Espana, every wednesday 11 am on www.antena6.fm, every saturday 11 am on www.masmusic.tv, every Saturday 11 am @ www.trancesonic.fm, every Saturday @ only4u-radio.de,every Sunday 23pm on www.fresh-fm.de (Germany) and weekly on www.radio-dj.pl.\nFOR BOOKING WORLDWIDE:\n\ndjcosmo.worldwide@gmail.com	https://assets.podomatic.net/ts/04/c4/19/djcosmo/3000x3000_14701199.jpg
2018	http://djcraigalexander.podomatic.com/rss2.xml	Craig Alexander's Musiquarium!	Craig Alexander	Thanks For Checking Out Craig Alexander's Musiquarium! Craig Alexander has been a staple in Chicago House Music for 30 years.  His love for the music began in the early 80s when he attended The Muzic Box where he heard the Legendary Ron Hardy play for the first time. Listening to Ron helped him develop a style all his own that has rocked dance floors all over the world. Initially starting out as a promoter doing parties at the Legendary AKA's with Ron Hardy he quickly began manning the decks as a opener for his parties as more people caught his sets he began to get offered headlining sets. He's played alongside everyone from Glenn Underground, Paul Johnson & Dj Rush to Lil Louis and Thomas Bangalter(Daft Punk).His musical journey has taken him to several places including France, Switzerland, & Germany to name a few. He is relaunching Oblique Records Digital in 2012. \nFor Bookings: obliquerecords@gmail.com\nContact:www.facebook.com/djcraigalexander or www.facebook.com/craigalexanderII	https://assets.podomatic.net/ts/ec/51/23/djcraigalexander/3000x3000-823x823+3+0_11241497.jpg
2019	http://djcraigcutupjones.jellycast.com/podcast/feed/2	DJ CRAIG CUT UP JONES ON iTUNES (Mini Mixes, Podcasts, Remix's, Bootlegs & More)	djcraigcutupjones	This is what I get upto in my home studio and its all free for you to download!\nMini Mixes\nPodcasts \nRemix's\nBootlegs\nand much much more! \nwww.djcraigjones.co.uk	https://djcraigcutupjones.jellycast.com/files/avatars-000004170093-xq5xfg-crop.jpg
2020	http://djcraigdalzell.podomatic.com/rss2.xml	Craig Dalzell Podcast	Craig Dalzell	ℹ️ NOTE TO ALL FOLLOWERS & SUBSCRIBERS! 29/04/2020\n\nOk guys, so after over 10 years of hosting my mixes here on Podomatic unfortunately i will not be renewing the service at the end of June and no new mixes from here on out will be uploaded. \n\nMixcloud has introduced live streaming with no copyright to their platform so i'm now also paying for that service and it must take priority in the longterm.\n\nAll my future mixes will only be accessible via their 'Select' subscription service here ⬇️\nhttps://www.mixcloud.com/DjCraigDalzellMixes/select/\n\nThanks for your understanding\nCraig\n\n⬇️ For more DJ mix videos SUBSCRIBE to my YouTube channel \nhttps://www.youtube.com/user/DjCraigDalzell	https://djcraigdalzell.podomatic.com/images/default/C-3000.png
2023	http://djcrownprince.podomatic.com/rss2.xml	Dj Crown Prince Podcast	Dj Crown Prince	Music Tings	https://assets.podomatic.net/ts/07/7b/2b/djcrownprince/pro/3000x3000_14304232.jpg
2024	http://djcruize.podOmatic.com/rss2.xml	Dj Cruize	Dj Cruize		https://djcruize.podomatic.com/images/default/D-3000.png
2025	http://djcutman.podomatic.com/rss2.xml	This Week in Chiptune	Chris Davidson	This Week in Chiptune is a weekly music show highlighting some of the best new Chiptunes from around the world. The show is hosted and mixed live by Dj CUTMAN. \n\nSometimes called chipmusic, 8bit, bitpop or lo-fi, chiptune music is sometimes created with old video game hardware, or obsolete technology. Because of the way it is created, Chiptune has a quality and style unlike most other forms of electronic music. Some chiptune musicians use modern music production tools in conjunction with 8-bit synths and hardware to create chiptune music with a modern edge. \n\nFull track-listings and download links for all music played on TWiC are available in the description of each episode, and also on ThisWeekInChiptune.com	https://ssl-static.libsyn.com/p/assets/a/e/1/e/ae1e0001ed40227a/This-Week-In-Chiptune-Podcast-art-2015.jpg
2026	http://djdaddymack.podOmatic.com/rss2.xml	The "Oh My God" Radio Show	DJ Daddy Mack	Listen to the #1 radio show for new and never heard before Hip Hop, Rap, R&B, Reggae and Reggaeton from underground and well-known artists. The show is hosted by DJ Daddy Mack and Co-Sign. Visit our website at http://dj-daddy-mack.tripod.com to learn more about the DJs and the show. Thank you for the support over the years!!! DOWNLOAD A SPECIAL 4 HOUR SHOW SEASON 4 EP. 4 HERE: http://hulkshare.com/0bn7w8jbt1yp	https://assets.podomatic.net/ts/dc/78/94/djdaddymack/3000x3000_612596.gif
2028	http://djdan.podbean.com/feed/	DJ Dan Presents Stereo Damage	DJ Dan	Stereo Damage is a monthly podcast hosted by world renowned house legend DJ Dan.  Every month he'll be showcasing some of his favorite tunes as well as featuring guest mixes from his favorite dj's and producers from around the globe.	https://djrpnl90t7dii.cloudfront.net/podbean-logo/powered_by_podbean.jpg
2031	http://djdannys.podOmatic.com/rss2.xml	DJ Danny S podcast	Daniel Schofield	An hour of uplifting Funky house for the pleasure of you and you're ears!	https://assets.podomatic.net/ts/57/59/14/djdannys/3000x3000_2429259.jpg
2032	http://djdany.podfm.ru/MixPodCast/rss/rss.xml	DJ Dany's Audio Mix Podcast	DJ Dany	The Freshest music only in this audio mix podcast. Young DJ from Kazakhstan presents the best Progressive, Electro and Club house tracks. \n \nSubscribe this podcast and you'll be notified of new additions. \n \nWelcome and be with "DJ Dany's Audio Mix Podcast"! \n \nContact info: \n \nEmail: lektor-d@mail.ru \nVK: vk.com/danyman \nSkype: Lektor-d \nPromoDJ: djdany.pdj.ru	http://file2.podfm.ru/28/284/2843/28430/images/lentava_33066_1_30.jpg
2033	http://djdaved.podomatic.com/rss2.xml	Dave Aura EDM & Deep House	dave Aura	if you like what you hear please leave me feedback on the iTunes store :)\ndjdaveaura.com\ntwitter     @DjDaveAura	https://assets.podomatic.net/ts/0a/26/27/e36dave/3000x3000_9912080.jpg
2035	http://djdavereeves.podOmatic.com/rss2.xml	TENACIOUS PODCAST	Tenacious UK	**Welcome to The Tenacious Podcast**\nJoin us LIVE Every Thursday From 10pm & Monday from 1pm on London's Centreforce Radio 883 DAB.\n              \nABOUT US.\nFrom his very early school years all Dave wanted to do is play music, so after playing lots of private parties in the late 80's and DJ'ing in the local clubs, he very quickly got involved with the Kent Soul Festivals, which led on to securing his first ever radio show on Sunrise 88.75 in London. With a huge passion for the music and the buzz of doing radio show's, he had shows on many other stations too over the years including Juice FM, Flex FM, Pulse FM, Fresh Radio UK and most recently Select Radio. Dave was also resident for many events over the years including The Camber Weekenders, Seduction Allnighters in Margate and the The Seduction Weekender's in Great Yarmouth, The Caister Soul Weekender and The South Coast Weekenders at Pontins in Camber Sands, these were major events to be involved with over the years. Dave has also held weekly club residencies for many big nights which include The Devious Events, H20 at Cales, M20 in Ashford, Lydd Watersports and Club Class in Maidstone playing alongside some of the biggest names on the scene every week. Dave has also played on the White Isle in Ibiza many times for various events inc Judgement Sunday's, Coastline, Es Paradis and many more.\n\nAfter years of DJ'ing, Dave set up a recording studio with his younger brother Steve and close friend Lewis in 1998 and started making uplifting Trance. With a little bit of success over a few years under the name 'Aptness', and their biggest track called 'The Answer, which Graham Gold signed to his Good as label, went on to become one of Judge Jules's favourite tracks of 1998 and also Graham Gold's 'Kicking Cut' on Kiss. 'The Answer' also appeared on various mix albums including Ministry's 'Clubbers Guide to 99, Trance Nation 2 and many more including a footie Playstation game. During this time they also did a few remixes inc one of Tiesto's very early tracks called 'Theme from Norefjell'.\n\nWith ever changing scene of dance music over the years and the Trance scene becoming more and more commercial, in 2013 the lads decided to take their productions in a new direction and that's when the name Tenacious was born, focusing on Underground House Music and driving energetic Bass Driven Tech House. Since then Tenacious have had tracks and remixes signed and released on some quality independent dance labels such as PP Music, Hotfingers, Jeepers, Subteranneo, Influential House, Onefold DGTL, Summerized Sessions, Whorehouse Records, Tropical Velvet and many more.\n\nWatch out for Brand New Music Forthcoming in 2019 on Criminal Hype Records, Rising High Records, Sleazy Deep, Onefold DGTL, New State Music & Sexy Trash.\n\nCatch Tenacious Radio Show Every Thursday Night from 22.00 hrs (GMT) on Londons CentreForce Radio 883 DAB & Online.	https://assets.podomatic.net/ts/40/33/18/djdavereeves/pro/3000x3000_13887375.jpg
2036	http://djdavids.libsyn.com/rss	DJ DAVID S OFFICIAL PODCAST	DJ DAVID S	Best known for his 1000 plus remixes on Crooklyn Clan, DJ David S continues to make his mark in the dj game. Born and raised in New Jersey, David is veteran with over 10 plus years in the club business.. For all bookings contact thedjdavids@gmail.com	https://ssl-static.libsyn.com/p/assets/0/3/f/a/03fae6eda248a2ea/IMG_9192.jpg
2037	http://djde2ce.podomatic.com/rss2.xml	DJ Deuce's Mixshow	DJ Deuce	The Elitegiance DJs holding it down!!!! Please enjoy the ride and PLEASE send feed back. REQUESTS are always welcome, but please keep in mind, I'm a Hip Hop, R&B, Top 40 style dj. I host and do mixtapes that will be featured here, and will be looking for songs of the week! Thank you for stopping by and please share with your friends!\nLike Me on Facebook facebook.com/pages/DJ-Deuce/ \nEmail me djde2ce@gmail.com\nDJ Deuce's Podcast\nhttp://itun.es/i6JY5pm #iTunes \nhttp://djde2ce.podomatic.com #podcast	https://assets.podomatic.net/ts/97/89/6a/djde2ce/pro/0x0_8548326.jpg
2038	http://djdeaneg.podomatic.com/rss2.xml	DJ Dean E G's Podcast	Dean-E-G	Dean E G's Podcast is a free mix tape series with each episode featuring a mash up of all genres of music. So if you like HipHop, RnB, Dancehall, FunkyHouse, Dubstep, Trap etc... then subscribe rate and review :-)	https://assets.podomatic.net/ts/fb/00/cb/deaneg85/3000x3000_7936761.jpg
2040	http://djdellmatic.podomatic.com/rss2.xml	The Dj Dellmatic Podcast	Dj Dellmatic	The Record Making & The Record Breaking....DJ DELLMATIC, brings new music and new artists to the podcast world. Dj Dellmatic's Podcast is the #1 Podcast for hearing new talent and great music!!	https://assets.podomatic.net/ts/21/c9/7b/djdellmatic/3000x3000_13126320.jpg
2041	http://djdenimusic.podomatic.com/rss2.xml	Deni Music	Deni Lenhard	Fresh House Music and electronic beats,\nbootlegs, mash ups and remixes!\nAll in one place!	https://assets.podomatic.net/ts/68/fa/14/djdenimusic/3000x3000_5834142.jpg
2042	http://djdetroit.podOmatic.com/rss2.xml	DJ Detroit	Core DJ Detroit	Core DJ Detroit doing what I do best....Mixing!  Hit me up in itunes and "Like" the facebook page at www.djdetroit.com.\n\nTwitter: @coredjdetroit\nInstagram: @coredjdetroit\nSnapchat: @Coredjdetroit\nPeriscope:@Coredjdetroit	https://assets.podomatic.net/ts/fb/eb/db/djdetroit/pro/3000x3000_6661745.jpg
2043	http://djdexi.podomatic.com/rss2.xml	Dj Dexi - Mixology Podcasts	lisa mccall	Welcome to the Mixology Show!\n\nDexi / Lisa May are residents of the Mixology Show along side Bexta, Nik Fish, Soul- T, Dj eM, Dj Husband & DBS. You can catch her sets every 3rd weekend of the month broadcast on:\nDi fm -  Noon US (est) * 5pm UK  *18:00 CET\nBam Radio  - 9pm Fridays (aest)\nKiss FM - 2am Saturday Nite (aest)\n\nBookings \nEmail Bec: mixmusicmanagement@gmail.com\n\nwww.facebook.com/dexidj\nwww.newcastlerockers.com\nwww.djdexi.podomatic.com	https://djdexi.podomatic.com/images/default/D-3000.png
2045	http://djdivago.podomatic.com/rss2.xml	DJ Divago	DJ Divago	Originally from Switzerland, Divago has traveled the world and been inspired by many different cultures and musical tendencies. More than sixteen years ago, he moved to New York City where he discovered the exciting Manhattan nightlife and its extravagant fusion of styles. Getting to know various Djs of the hippest clubs of New York City, he quickly got hooked to the art of deejaying. During those years, he also developed a new passion for Electro-World Music and its fusion of melodies and instruments from around the planet.\n\nIn 2005, Divago moved to Ecuador where he lived for almost 10 years. He quickly became renown in the electronic scene, playing at different venues and events around the country such as Lost Beach Club (Montañita), Frodia, the White Party. He became resident dj at Colors Disco where he played for more than 6 years, and created & hosted a weekly night of Ethnic House named 'Karmadelic' in one of the most renown lounge in Guayaquil - La Paleta. Later on, Divago started hosting his own radio show 'The Divago Effect' on the only American radio in Ecuador, playing the newest House & Dance records from top charts.\n\nDivago also became known in the world of fashion, becoming the official dj at Ecuador Fashion Week, and playing at important fashion shows around the country, bringing new and fresh house beats on the runways.\n\nIn 2013, Divago moved to Santiago (Chile) looking to expand his career on the electronic scene.\n\nHis club style is a mix of Tech-Prog-House & Funk-Electro-Dance Music, depending on the venue. From nights of pure House music, mixing Progressive with Deep and Tech, to nights of commercial crowd-pleasing dance hits, Divago always surprises his crowd with original sets to maintain good and positive energy on the dance floor.\n\nHis lounge style, on the other side, is a mix of World-Fusion, Funky-Jazz House Music, combining chillout sounds with ethnic flavors such as Arabic, gipsy, African and Asian rhythms, an ideal combination to escape the everyday routine and start the night before hitting the clubs.\n\nAlways on the lookout for new music and future club bangers, Divago brings the ultimate remixes from the USA and Europe directly to the clubs and makes sure the crowd doesn't stop dancing until the early hours of the morning.	https://assets.podomatic.net/ts/81/54/11/djdivago/3000x3000_8878143.jpg
2046	http://djdm.podOmatic.com/rss2.xml	Pod Underground One	DJ DM	Pod Underground One is music from Florida's underground house music scene mixed by DJ's across Florida. Featuring DJ DM as the host. Hailing from Orlando, FL to the world, DJ DM is in the mix every Friday night along with special guest DJ's	https://assets.podomatic.net/ts/19/ce/55/djdm/1400x1400_609013.jpg
2047	http://djdmx303isme.podOmatic.com/rss2.xml	DJ DMX Denver's Numero1	David DJ D.M.X. Mangum	Once upon a time, there was a 17 year old kid who became influenced to become a DJ by Jam Master Jay (RIP),that was 1984.Fast Forward to 2011. This DJ has graduated to 303 star General of the DJ Army. Give a listen to what 25+ years in the trenches does with his weapons of choice, Turntables, CDJ's, Serato and Ableton!!!  Please feel free to post any comments you like on the shoutout page at http://djdmx303isme.podOmatic.com or follow me at twitter.com/djdmx303 or dunit303	https://djdmx303isme.podomatic.com/images/default/podcast-4-3000.png
2049	http://djdoublen.podomatic.com/rss2.xml	DJ Double N's Podcast	DJ Double N		https://djdoublen.podomatic.com/images/default/podcast-1-1400.png
2077	http://djesquirenyc.podomatic.com/rss2.xml	THE TAKEOVER w/ DJ ESQUIRE	DJ ESQUIRE NYC	The Takeover with DJ Esquire airs LIVE on www.beatminerzradio.com!!!	https://assets.podomatic.net/ts/2d/e3/66/djesquire1200/3000x3000_7161408.jpg
2078	http://djessay.podomatic.com/rss2.xml	David-E's Altered Jukebox	David E's Altered Jukebox	Promotional DJ Mixes	https://assets.podomatic.net/ts/e3/c5/0b/djessay/0x0_11557064.jpg
2050	http://djdougbrown.podOmatic.com/rss2.xml	Dj Doug Brown	Dj Doug Brown	FOR PROMOTIONAL USE ONLY.\nLEAVE A COMMENT. GIVE ME A RATING.\nFOLLOW ME. BECOME A FAN.\nEach Episode, A Full Hour Of Free Jam Pack Download Music At Your Fingertips Ready To Explode! \nThere's Jazz, Hip Hop, R&B, Pop, Caribbean, House, Classic Hits! Different Styles to Your Liking. \nAll Guarantee To Make You Believe You're In A Private Room Ready To Party Hard.   \nBooking Infor:\ndjdougbrown@gmail.com.\nfacebook.com/Dj Doug Brown. Professional Dj For Your Needs\nfacebook.com/djdougbrown.\ntwitter.com/djdougbrown.\nhttp://djdougbrown.podomatic.com/rss2.xml	https://assets.podomatic.net/ts/57/b1/14/djdougbrown/3000x3000_1671848.jpg
2051	http://djdq.podomatic.com/rss2.xml	DJDQ Podcast	DJ DQ		https://djdq.podomatic.com/images/default/podcast-2-1400.png
2052	http://djdrake.podomatic.com/rss2.xml	DjDrake804 Podcast	DjDrake804	FEATURING DIFFERENT GENRE OF MIXES  FOR ALL AGE GROUPS MORE INFO CONTACT ME ON \nTWITTER@DJDRAKE804 & WWW.FACEBOOK.COM/DjDrakeRVA\nBOOKINGS OR QUESTIONS:DJDRAKE804@GMAIL.COM\nBusiness Phone 804-874-6353	https://assets.podomatic.net/ts/e8/7f/c0/podcast97454/pro/3000x3000_12670433.jpg
2053	http://djdswift.podOmatic.com/rss2.xml	DJ D-Swift In The Mix	DJ D-Swift	DJ D-Swift’s style, mixing, and song selection is what makes him one of the premier DJs in the Valley.  He’s smooth on and off the turntables.  You will always catch him with a smile on his face because he put a smile on yours.  Next time you’re out dancing and hear a song you love that you’ve never heard in the club…Guess what, it might just be a 6’4” Gentleman they call DJ D-Swift in the booth!	https://assets.podomatic.net/ts/1f/4b/fa/djdswift/3000x3000_1008455.jpg
2054	http://djdubfire99.podomatic.com/rss2.xml	Reggae & Dancehall Vybz	Selecta Dubfire	Selecta Dubfire Is A Reggae/Dancehall DJ.\nHe has carried himself as one of the best Reggae Dj's around. His choice of Music always seduces his listeners ears!..His style of mixing is one of the smoothest in the genre...	https://assets.podomatic.net/ts/21/f4/37/djdubfire99/3000x3000_8442931.jpg
2055	http://djduce.podOmatic.com/rss2.xml	DJ Duce Show !!!	Dj Duce	Monthly hip hop and r&b podcast with emphasis on indy producers and artist. Check out www.djduce.wordpress.com !!!!	https://assets.podomatic.net/ts/8f/80/04/djduce/3000x3000_5266029.gif
2056	http://djdunnoelectro.podOmatic.com/rss2.xml	DJ Dunno  - Fidget/Dirty Electro House Podcast	DJ Dunno	** Can't afford the subs to Podomatic anymore, and till I pay I can't post anymore, so sorry guys. Thanks for the messages of enouragement tho!!** Fairly frequent podcast of filthy, dirty electro/fidget house! If you know of anyone who would like this podcast then please spread the word!! The more people that listen the better!! NOW mixed using NI's Traktor Scratch!!! NO MORE POPS AND CLICKS!!! No talking, just straight live mixing on two turntables using vinyl!!	https://assets.podomatic.net/ts/6d/2b/11/djdunnoelectro/3000x3000_3382673.gif
2057	http://djdunz0.podomatic.com/rss2.xml	Robotic Rhythms with DJ Dunz0	DJ dunz0	Spinning my latest and past favorites in progressive and electro house!	https://assets.podomatic.net/ts/b4/29/19/thebrock357/pro/3000x3000_3631631.jpg
2058	http://djeakut.podomatic.com/rss2.xml	DJ EAKUT Podcast	DJ EA KUT	MIXTAPES, LIVE CLUB SETS AND MIX SESSIONS	https://assets.podomatic.net/ts/8a/f6/96/djeakut/3000x3000_8317176.jpg
2059	http://djeasyk.podomatic.com/rss2.xml	THE SOUND ELECTRO OF EASY K	DJ EASY K		https://assets.podomatic.net/ts/e2/b4/c7/khams93150/3000x3000_7006602.jpg
2060	http://djeazyk.podomatic.com/rss2.xml	Dj Eazy-K What's Going On	Dj Eazy-K	DJ EAZY-K "The MVP" fondateur du collectif de dj "What's Going On Dj Crew".\n\nTwitter : www.twitter.com/deejayeazyk\n\nFacebook : www.facebook.com/pages/DJ-EAZY-K-…/179639858767380\n\nInstagram : Mistercuffyochick\n\nBooking : djeazyk@gmail.com\n\nRetrouver Dj Eazy-K tous les samedis avec Dj Sreal de 23h à Minuit pour l'émission "Urban Mix" sur Urban Hit 94.6 et 91.5 site internet www.urbanhit.fr et l'application Iphone et Androïd "Urban Hit".	https://assets.podomatic.net/ts/d2/9f/1f/djeazyk/3000x3000_3560667.jpg
2062	http://djeclypse.podomatic.com/rss2.xml	Trance Station - DJ Eclypse	DJ Eclypse	Bringing you the most incredible and technically designed trance, progressive, and breakbeat theme based DJ mixes in the galaxy!\n\nFollow on facebook @ http://facebook.com/djeclypseusa	https://assets.podomatic.net/ts/33/f2/5d/djeclypse/3000x3000_3619860.jpg
2063	http://djeddieelias.podomatic.com/rss2.xml	EDDIE ELIAS "INTO SOUND" PODCAST SERIES	EDDIE ELIAS		https://djeddieelias.podomatic.com/images/default/E-3000.png
2064	http://djeddyoneb.podfm.ru/PL/rss/rss.xml	PROGRESSIVE LINE	djeddyoneb	Progressive Line is published twice a week on Clubberry.fm: Saturdays at 10:00(gmt) on the Trance channel, and on Sundays at 16:00(gmt) on  House Channel. As well, the day after the broadcast Progressive Line out as a podcast * on Beatport and other store.	http://file2.podfm.ru/36/367/3675/36757/images/lent_43054_big_20.jpg
2065	http://djedilhernandez.podomatic.com/rss2.xml	DJ Edil Hernandez's Podcast	DJ Edil Hernandez	Collection of my music sets... enjoy!  Follow me on facebook: https://www.facebook.com/djedilhernandez	https://storage.buzzsprout.com/variants/4yranh6uw77n3v25b1o6bkeotqi4/8d66eb17bb7d02ca4856ab443a78f2148cafbb129f58a3c81282007c6fe24ff2.jpg
2066	http://djedlee.podOmatic.com/rss2.xml	Ed Lee	Ed Lee		https://assets.podomatic.net/ts/2a/66/68/djedlee/3000x3000_9020088.jpg
2067	http://djeieio.podbean.com/feed/	DJ eieio	DJ eieio	hillbilly techno music	https://pbcdn1.podbean.com/imglogo/image-logo/786/farm.jpg
2069	http://djek511.podomatic.com/rss2.xml	E.k Radio	Dj E.k	Facebook - http://www.facebook.com/djek511 \nEmail - dj-ek@hotmail.com \nTwitter - http://twitter.com/Dj_Ek \nYouTube - http://www.youtube.com/myspacecomdjek511 \nGoogle + - https://plus.google.com/103529321555769116209 \nSoundCloud - http://soundcloud.com/djek \nMixCloud - http://www.mixcloud.com/djek511	https://assets.podomatic.net/ts/01/34/7a/dj-ek/1400x1400_7024449.jpg
2070	http://djeliascabuzz.podOmatic.com/rss2.xml	Funky House New York Style	DJ Elias CabuzZ	Dj Elias CabuzZ, Born in Brasilia, Elias CabuzZ initiated his career as a Dj in July of 2002 introducing Hip-Hop in the northeast of Brazil playing for 4 year's until change for House Music, and Create the Funky House New York Style. Since his early childhood Elias was always fascinated for music and his passion led him to work producing many projects and events that connected Brazilian culture to international trends in music. For 6 years Dj Elias CabuzZ showcased his talent throughout Brasil, playing in various states such as: Sao Paulo, Rio de Janeiro, Bahia, Ceara, Brasilia D.F., Paraiba, Rio grande do Norte, Tocantins, Piaui, Alagoas e Pernambuco, among others. In 2007, Elias decided to live in New York City for 6 months and invest in his career by taking an electronic music production course at SAE- Institute of Technology; he also had the opportunity to play in various clubs and events in the Big Apple scene. Since he always enjoyed a good challenge, he felt he should test his music talent and try a different beat, so he introduced house music in his Dj life and experimented with a set that became a hit. Elias CabuzZ has a degree in Marketing and Strategic Communication. Worked As an event planner for 15 years, furthermore he planned and produced plenty of events, such as: Festival de Verao do Recife( Recife Summer Festival) – The festival lasts 2 days in the Chevrolet Hall, and it brings national artists and bands such as: Ivete Sangalo, Marcelo D2, Timbalada, Chiclete com Banana, Barao Vermelho, the bands vary every year. This event drew about 120 thousand guests. For 5 years he has planned and played in the electronic tent which also hosts the most renowned Dj’s in the electronic scene. Such as: Carlos Dallanese(SP), Julio Torres(SP), Leozinho(GOA) e Rodrigo Parscionik(GOA), Bruno V.(PE), Rafael Correia (RN), Marcio zanzi(SP), Edu Brussi(SP) ,among others. Forro da Capital – For 5 years he has produced and played in the electronic tent of the event together with various DJ’s whom are a part of the electronic music in Brazil. The event happens every year at the Chevrolet Hall with a special theme called Sao Joao. Sao Joao is a northeastern celebration that involves typical dancing and food. This event attracts around 100 thousand guests a day. Like the Recife Summer festival, Forro da Capital has funding from the Rede Globo television network. Other places he had played: Barrozo Club, Recife beats, Skol Spirit, Sauipe Folia, Red Bull FlugTag, Mad Pub, Hooters, Music Club, Apotheke Club, Baronette (RJ), Nox Club (PE), Lotus (NY), Audrey Club, Fashion Club, Over Point, Camarote Carnatal, Camarote Flying Horse Recifolia, Recife Indoor, Mansion Club (MIA), Mucuripe (CE), Reveillon dos Ansiosos (Ilha de Fernando de Noronha –PE), No Reason – Hotel Dorisol (PE), Le Souk (NY), Friend’s of House – closed party (NJ), Opening for Offspring –Chevrolet Hall(PE), Opening for Ja Rule – Chevrolet Hall (PE). The DJ Elias Cabuzz, played together with other music artist and shared some mixed songs with many of the Best DJ’s in Brazil and in the World, like: Ale Reis (SP), Buga(SP), Fabricio Pecanha(SP),Mario Fischetti(SP),Milk(SP),Anderson Noise(SP),Meme(RJ),Carlo Dallanese (SP),Cabal(SP),Gabo(SP),Marky(SP),Patife(SP),Philip Braunstein, Life is a Loop(SP), Leozinho(GOA), Rodrigo Ferrari(SP) Rodrigo Paciornik(GOA), Deep Dish, Ja Rule tour Brazil, Offspring tour Brazil, Bruno V(REC), Gui Boratto(SP), Julio Torres(SP), Edu Brussi(SP), Spin Easy(Snoopy Dog DJ),Layo and Bushwacka, Ean Golden (Usa), Leo B(REC), Benny Benassi, and other’s.	https://assets.podomatic.net/ts/3a/27/d4/djeliascabuzz/3000x3000-603x603+127+34_6168912.jpg
2071	http://djenglish.podOmatic.com/rss2.xml	dj english to the world	DJ ENGLISH	dj english to the world	https://assets.podomatic.net/ts/91/ef/88/djenglish/pro/3000x3000-0x0+0+0_11632893.jpg
2072	http://djepicc.podomatic.com/rss2.xml	DJ EPICC  Podcast	shaun canty		https://assets.podomatic.net/ts/b6/9b/35/djepicc/3000x3000_8956661.jpg
2073	http://djernie.podomatic.com/rss2.xml	DJ Ern Chicago's Soul	DJ Ern	Dj Ern will be updating his Chicago Soul Mixes every couple of weeks. Stay tune for future house dancing.	https://assets.podomatic.net/ts/25/89/35/swime5/3000x3000_3807617.jpg
2075	http://djesalsala.podomatic.com/rss2.xml	SALSABRAVARADIO.COM  ♫ ♪ ♫ ♪  Con DJ.E!	Salsa Brava Radio Podcats ! (DJ.E)	The Best Salsa Brava (Hard Salsa) Podcast on the Internet Period! DJ.E. not only brings you Hardcore Salsa but also 'Los Poderes de la Salsa' in the Music he Plays! Maferefun Eleggua! Visit our official website Salsabravaradio.com ♫ ♪ ♫ ♪	https://assets.podomatic.net/ts/88/a0/01/salsabravaproductionsla/pro/3000x3000_9156780.jpg
2079	http://djessey.podomatic.com/rss2.xml	DJ Essey's Salsa Sickness	Ed Essey	Classics and underground hits from DJ Essey's vault.  Salsa, cha cha, bachata, and other terrific latin music.	https://djessey.podomatic.com/images/default/podcast-4-3000.png
2080	http://djeveryday.podOmatic.com/rss2.xml	Dj Everyday	Dj Everyday	A mixture of tech house and techno	https://assets.podomatic.net/ts/0c/b6/d7/djeveryday/3000x3000_10539460.jpg
2081	http://djevildee.podOmatic.com/rss2.xml	DJ EVIL DEE'S PODCAST !!!!!	DJ EVIL DEE .		https://djevildee.podomatic.com/images/default/podcast-4-3000.png
2082	http://djfantompodcasts.podomatic.com/rss2.xml	DjFantom's Podcasts	DjFantomPodcasts	Dj Fantom Podcasts, Mixes and Live Recordings \n\nDJ FANTOM\nwww.DJFANTOM.net\nDjFantom.Mobile@Gmail.com\nwww.Facebook.com/TheRealDjFantom\nwww.FANTOMRADIO.com\nTwitter.com/DjFantom\nInstagram : @DjFantom	https://assets.podomatic.net/ts/cf/71/21/fantomradio/0x0_7278335.jpg
2083	http://djfatal.podomatic.com/rss2.xml	Wax Laboratory Radio	DJ Fatal	music for pleasure	https://assets.podomatic.net/ts/4f/36/6c/djfatal/3000x3000_8772382.jpg
2084	http://djflame.podomatic.com/rss2.xml	The Anointed Mic Check(tm) with DJ  Flame	DJ  Flame	DJ FLAME - f/n/a DJ LaSpank of the Legendary Mercedes Ladies HOST/VOCALIST/PRODUCER On-Air Personality of "The Anointed Mic Check(tm)"\nof WHCR 90.3FM www.whcr.org Wednesdays 5am - 8am Studio 212) 650-6903	https://assets.podomatic.net/ts/83/dd/a5/djflame/3000x3000_11651099.jpg
2085	http://djflexx.podomatic.com/rss2.xml	FLEXX's Podcasts	DJ Flexx	***House Nation Vol 2***\n\nKid Massive feat Jim C - House Music(Move Your Body) (Muzziak Remix)  \nLucas & Steve feat Bethany - Blinded (Original Mix)  \nMatt Caseli & Terry Lex feat Catraz - Born Slippy.Nuxx (Original Mix)  \nEduardo De Rosa - Reason (Original Mix)  \nChus & Caballos - La Colombiana (Original Mix)  \nMike Mago - The Gift (Mark Knight Remix)  \nGorgon City feat Jennifer Hudson (Erick Morillo Dub)  \nChilly - Driver (Original Mix)  \neSQUIRE & Jolyon Petch - Rhythm Is A Dancer (Original Mix)  \nMartin EZ - If I ruled (Original Mix)  \nKevin Andrews - The Music (Original Mix)  \nFelguk - Buzz Me (Bruno Barudi Remix)  \nLana Del Ray - Ultraviolence (Hook N Sling Remix)  \nDr. Kucho! & Gregor Salto - Can't Stop (Oliver Heldens & Gregor Salto Remix)  \nOliver Heldens - Koala (Original Mix)  \nPeter Gelderblom, Randy Colle - Got To Be Good (Original Mix)  \nDario Nunez - The Drop (Original Mix)\n\n\nThanks for the support and to all of you who have donated via paypal....help the artist!\n\n\nDon't forget click "Subscribe" to add to itunes for automatic downloads or DJ Flexx podcasts in the itunes store "subscribe for free"	https://assets.podomatic.net/ts/ca/77/d7/robdahnke/3000x3000_10241120.jpg
2086	http://djflize.podomatic.com/rss2.xml	Dj Flize	Dj Flize	All tracks are mixed by hand with no computer assistance, bpm counter or any other electronic device such as e.g. Traktor SYNC...!	https://assets.podomatic.net/ts/b4/76/e8/greenstirit/1400x1400_10138581.jpg
2087	http://djfredr.podomatic.com/rss2.xml	DJ FRED R's Podcast	DJ FRED R	Le Vertifight est une compétition de danse electro. D'abord cantonné à Paris, le succès des compétitions s'est élargi au niveau national puis mondial avec pas moins d'une vingtaine de pays engagés : Portugal, Canada, Algérie, Maroc, Corée, Russie, Biélorussie, Mexique, Espagne, Suisse etc etc. \n\nDepuis la création du Vertifight par Steady, Hagson et Youval, FredR est le dj officiel du Vertifight parisien (Vertifight Kingz, Vertifight Origine etc.), et également des sélections nationales et mondiales, et donc du Championnat de France et du Championnat du Monde.	https://djfredr.podomatic.com/images/default/podcast-1-1400.png
2088	http://djfrickerfuturebass.podomatic.com/rss2.xml	DJ Paul Fricker Mixes	DJ Paul Fricker	https://www.facebook.com/dj.paul.fricker\n\nhttps://podcasts.apple.com/gb/podcast/dj-paul-fricker-mixes/id573589632	https://assets.podomatic.net/ts/55/22/e5/frix2/3000x3000_10360847.jpg
2090	http://djgaryb.podomatic.com/rss2.xml	Da Slackers Mid Day Mix with DJ Gary B	DJ Gary B	Mixed Exclusively by DJ Gary B "Da Slackers Mid Day Mix" was created for those music minded individuals who love listening to finely crafted quality mixed music throughout the day.	https://assets.podomatic.net/ts/2f/60/df/djgaryb/3000x3000_3819378.jpg
2091	http://djglimpse.podOmatic.com/rss2.xml	Glimpse's Podcast	Glimpse		https://djglimpse.podomatic.com/images/default/podcast-4-1400.png
2092	http://djglorious.podomatic.com/rss2.xml	Glorious Visions	Lockstone	3 Weekly Trance podcast showcasing tracks old and new from around the world. Mixed and presented by myself and aired first on 1Mix radio\n\nAlso available on Demented FM	https://assets.podomatic.net/ts/4a/3d/7d/podcast57332/3000x3000_9774082.jpg
2093	http://djgoodboi.podomatic.com/rss2.xml	Dj GoodB.O.I.'s #30MinuteMashUps	Dj GoodB.O.I.	30 minutes of your favorite music featuring your favorite artists and introducing new ones, mixed up by @DjGoodBOI available to download for free!	https://assets.podomatic.net/ts/97/e1/e5/djgoodboi/pro/3000x3000_11462138.jpeg
2095	http://djgrind.podomatic.com/rss2.xml	DJ GRIND | The Daily Grind	DJ GRIND	Podcasts from DJ GRIND, Billboard #1 Remixer & Producer	https://assets.podomatic.net/ts/d3/1f/08/djgrind/pro/3000x3000_12568821.jpg
2096	http://djgsp.podomatic.com/rss2.xml	DJ GSP's podcast	DJ GSP	OFFICIAL WEBSITE: http://www.djgsp.com\nFACEBOOK FAN PAGE:  \nPODCAST: http://djgsp.podomatic.com \nSOUNDCLOUD: https://soundcloud.com/gsp-814592702\nHEARTTHIS: https://hearthis.at/djgsp/\nLEGITMIX: http://legitmix.com/discovery/remixer/58435/GSP\nMIXCLOUD: \nhttp://www.mixcloud.com/georgespiliopoulos/ \nBEATPORT: http://www.beatport.com/artist/gsp/326045\nYOUTUBE CHANNEL: http://www.youtube.com/djgsp	https://assets.podomatic.net/ts/ab/0a/12/djgsp18/pro/3000x3000_10881549.jpg
2098	http://djhanif.podOmatic.com/rss2.xml	relevant sound/dj hanif	dj hanif	soulful mixes by relevant sound's dj hanif.	https://assets.podomatic.net/ts/1e/74/71/djhanif/3000x3000_771769.jpg
2099	http://djhenryhall.podOmatic.com/rss2.xml	All Mighty House Sounds By DJ Henry Hall	Henry Hall	DJ Henry Hall is a New York City DJ. Henry plays a mixture of soulful and deep House Music layered with beautiful vocals. He has spun at many clubs across the country. As a result of overwhelming demand, Henry produces a monthly podcast here at http://www.djhenryhall.podomatic.com - Here you can also find, complete track listing and subscribe with you favorite RSS reader or podcatcher. \n\nFor booking arrangements: djhenryhall@yahoo.com	https://assets.podomatic.net/ts/cc/5d/73/djhenryhall/pro/3000x3000_2180192.jpg
2100	http://djherberttonn.podomatic.com/rss2.xml	DJ Herbert Tonn oficial	DJ HERBERT TONN	Em mais de 2 décadas de carreira, Herbert Tonn tornou-se referência como DJ e hoje é um dos nomes mais importantes da cena musical LGBT do Brasil.\n\nHá 24 anos é DJ RESIDENTE aos domingos, no club BLUE SPACE em São Paulo, sendo um dos únicos Djs brasileiros a ter uma residência num night club por tanto tempo.\n\nHá quase 5 anos faz parte do time de Djs residentes do selo brasileiro "GRUPO SUPERFESTAS", grupo que comanda algumas das festas e after parties mais importantes de SP, tais como: CODE After, BIGGER Party, JUNGLE Party, EUPHORIA After, BIG After, ENERGY After, HOT After, entre outras festas e festivais do Grupo. \n\nHá quase 5 anos é um dos DJs convidados de uma das maiores festas de SP, a URSOUND, selo respeitado em todo o Brasil, onde Herbert teve o prazer de fazer parte do line nos aniversários de 10 anos (Via Matarazzo), 11, 12 e 13 anos (AUDIO club SP).\n\nHerbert também esta presente no line da BIGGER PARTY, como Dj convidado, ao lado de grandes nomes da cena, uma festa que tornou-se reconhecida internacionalmente e sucesso nacional.\n\nSua experiência o torna um dos Djs brasileiros mais requisitados a fazer LONG SETS ou XTEND SETS, com habilidade para tocar durante muitas horas.\n\n\nSua história...\nBIOGRAFIA\n\nSua trajetória se início nos anos 90, junto com a evolução musical e tecnológica. Logo no início ele se tornou residente dos maiores clubs de SP, entre alguns estão: RAVE, MASSIVO, ULTRALOUNGE e BCBG.\n\nAinda nos anos 90, foi convidado para gravar um CD pela gravadora PARADOXX, o cd BODY CULTURE by Dj Herbert Tonn, o primeiro CD feito exclusivamente por uma gravadora voltado ao público LGBT, com turnê pelo Brasil em razão do sucesso de vendas, tornando-o conhecido em todo o país.\n\nEm meados dos anos 2000, Inaugurou o Programa FREEDOM na Rádio Energia 97fm e hoje participa como DJ convidado deste programa que até hoje é um grande sucesso.\n\nParticipou durante anos do FESTIVAL SPIRIT OF LONDON no Sambódromo do Anhembi, também comandado pela Rádio Energia 97fm SP.\n\nHerbert Tonn foi DJ residente por 9 anos do club THE WEEK (Junho de 2006 - Março de 2015), tendo tocado em Festivais importantes do grupo como ETERNA FESTIVAL, INCREDIBLE WEEK, ACQUAPLAY, CARNAVAL FLORIPA, REVEILLON FLORIPA, TOY, etc, além de inaugurações dos clubs THE SOCIETY e GRAND METROPOLE.\n\nSua carreira internacional conta com apresentações em Vigo (Espanha), em Amsterdam na PRIDE para o selo holandês RAPIDO, em MALAGA (Espanha) e MYKONOS (Grécia) no LA DEMENCE CRUISE do selo belga LA DEMENCE.\n\nEle também é convidado para viajar por todo o Brasil ?? para comandar as pick-ups dos mais importantes Clubs, Festivais , Pool Parties, Afters e Festas em geral. \n\nAlguns lugares por onde passou são: Belém (Pará), Manaus (Amazonas), Goiânia, Brasília, Salvador, Fortaleza, João Pessoa, Maceió, Rio de Janeiro, Belo Horizonte, Curitiba, Florianópolis, Volta Redonda (RJ), Santa Catarina, Macapá (Amapá), Campinas (SP), Ribeirão Preto (SP), São José dos Campos (SP), São José do Rio Preto (SP) e muitos outros.\n\n\nTRILHAS EXCLUSIVAS &\nEVENTOS CORPORATIVOS\n\nAlém de toda sua história na cena musical, ele também realiza um trabalho diferenciado da noite: ELABORAR CONCEITO MUSICAL e TRILHAS SONORAS para Produtos, Marcas, Hotéis, Restaurantes, Lojas, Desfiles, etc.\n\nDentre alguns trabalhos neste seguimento destaca-se o CONCEITO MUSICAL criado exclusivamente para o HOTEL PULLMAN, marca internacional de hotéis que chegou ao Brasil em 2011 e hoje conta com 3 hotéis em SP.\n\n“A sua habilidade em se conectar com o público, em qualquer pista ou evento, o torna único no que faz.”\n(AO assessoria)\n\nENJOY THE MUSIC!!\n\nwww.djherberttonn.podomatic.com\nwww.facebook.com/deejayherberttonn\nwww.twitter.com/djherberttonn\niTunes store: DJ HERBERT TONN\n\n.::: PARA CONTRATAR :::.\nWT CREATIVE COMMUNICATION\nAO ASSESSORIA\nADRIANA DE OLIVEIRA\nm a n a g e r\nwtassessoria@hotmail.com	https://assets.podomatic.net/ts/48/da/d7/djherberttonn/3000x3000_13312093.jpg
2101	http://djhoproductions.podOmatic.com/rss2.xml	Rene Hoyo's Podcast	Dj Ho		https://djhoproductions.podomatic.com/images/default/podcast-3-1400.png
2102	http://djhousemikefeva.podOmatic.com/rss2.xml	DJ HOUSE MIKE FEVA	DJ HOUSE MIKE FEVA	DJ HOUSE MIKE FEVA brings you "FULL SERVICE" house music mixes every week! \n\nPlaying the best in old school house, disco classics, underground house, garage house & r&b house remixes!	https://assets.podomatic.net/ts/13/7d/e2/djhousemikefeva/3000x3000_731554.jpg
2103	http://djindo.podomatic.com/rss2.xml	Strictly Blazin	djindo@strictlyblazin.com (Strictly Blazin)	A selection of Dancehall, Afrobeat, Soca, Hip Hop, Reggae, R&B, and Electro vibes mixed by Strictly Blazin.	http://strictlyblazin.blubrry.net/wp-content/uploads/powerpress/STRICTLY_BLAZIN_LOGO_TROPICAL_podcast_feed_optimized.jpg
2104	http://djinferno.podomatic.com/rss2.xml	DJ Inferno's Podcast	DJ Inferno	The DJ known as “Inferno” has become a house hold name in the city of Las Vegas. Upon his arrival to Sin City DJ Inferno has gained residency after residency from his excellence in programming to extreme versatility. Ranging from Hip Hop, Rock, 80’s to House music, Inferno is able to read a crowd and deliver with great success. \n\nFrom his 2003 club debut inside MGM Grand’s highly rated “Dome”, DJ Inferno has managed to attain residencies at hot spots such as Rio’s VooDoo Lounge, Empire Ballroom to award winning venues like Studio 54, Tangerine & Hard Rock pool.\n \n\nIn 2005 DJ Inferno hosted a themed night called “Open Turntable Wednesdays” at the Ra Sushi Restaurant located on the Las Vegas strip. By booking several local DJ’s to spin each week and attracting attention from the media & his piers, DJ Inferno has created a “following” that any club owner sees as invaluable.\n\nSince then, Inferno has moved on to larger venues and has achieved huge accomplishments including working in his studio to produce some tracks of his own. DJ Inferno has proven to be one of the most sought after DJ’s in Las Vegas because of his talent as an entertainer and his hard work and dedication in promoting himself wherever he spins.\n\nCurrently DJ Inferno is traveling the country with the Travel Channel filming episodes of the hit TV Series "Ghost Adventures". He is also involved with another new show called "Paranormal Challenge" set to premier June 17, 2011 also on Travel Channel.\n\nFOR BOOKING INFORMATION \n(702) 205-2337	https://assets.podomatic.net/ts/bc/fc/ed/djinfernolv/3000x3000_5981555.jpg
2105	http://djjabinyc.podomatic.com/rss2.xml	DJ Jabi NYC's Podcast	DJ Jabi NYC	I love House Music... Progressive, Tribal, Electro, Deep, Tech, Vocal, OldSchool / NewSchool House Music... All Night long! \nd(-.-)b	https://assets.podomatic.net/ts/a9/e0/ed/jamesbell/pro/3000x3000_3297095.jpg
2106	http://djjackreinanyc.podomatic.com/rss2.xml	DJ Jack Reina	DJ Jack Reina	A progressive house DJ, Jack blends elements from disco/funky house to big room tribal and incorporates sounds as diverse as rock and electro to hot underground rhythms; all the while maintaining vocals and a familiarity for his audience.	https://assets.podomatic.net/ts/4f/b7/de/djjackreinanyc/pro/3000x3000_11332243.jpg
2107	http://djjams.backdoorpodcasts.com/index.xml	Dj JAM'S - 5 étoiles de l'ambiance	Dj Jam's	DJ JAM'S - OFFICIAL PODCAST !!	http://djjams.backdoorpodcasts.com/uploads/items/djjams/dj-jam-s-5-etoiles-de-l-ambiance.jpg
2108	http://djjaredalan.podOmatic.com/rss2.xml	Jared Miller's Podcast	Jared Miller		https://djjaredalan.podomatic.com/images/default/podcast-1-1400.png
2109	http://djjasoncrawford.podomatic.com/rss2.xml	DJ Jason Crawford, Washington, DC	DJ Jason Crawford	DJing isn't what I do for a living but other than marathons and triathlons, there are only a few things that give me as much pleasure as being in my music zone.  I hope you enjoy.  \n- jason	https://assets.podomatic.net/ts/67/06/ea/jasoncrawford70/3000x3000_6534654.jpg
2110	http://djjasonhilbert.podomatic.com/rss2.xml	DJ Jason Hilbert's Podcast	Jason Hilbert	Soulful, funky music for your ears.	https://assets.podomatic.net/ts/1b/03/cb/jasonhilbert92250/3000x3000_5642702.jpg
2111	http://djjayp.podOmatic.com/rss2.xml	Beats Across Borders	Jay P	Mixing up beats across genres from around the world and keeping it interesting:  house (deep, tech, soulful, funky, tribal, latin, disco), broken beat, nu jazz, re-edits, downtempo, balearica, deep techno, afrobeat, retro, disco, world beat	https://djjayp.podomatic.com/images/default/B-3000.png
2112	http://djjayskillz.podomatic.com/rss2.xml	Jay Skillz's Podcast	Jay Skillz		https://djjayskillz.podomatic.com/images/default/J-3000.png
2113	http://djjazzyjeff.podomatic.com/rss2.xml	DJ Jazzy Jeff's Podcast	DJ Jazzy Jeff		https://assets.podomatic.net/ts/99/e5/fe/jefftownes/3000x3000_3348136.jpg
2114	http://djjbburgos.podOmatic.com/rss2.xml	DJ JB Burgos Podcast	JB Burgos		https://assets.podomatic.net/ts/2b/26/b8/podcast1583/pro/3000x3000_15110375.jpg
2115	https://www.perimeter.org/podcasts/rots/rotsperimeter.xml	The Rest of The Story	Frances Hoyt	Series compilation on the book of Revelation, taught at Perimeter Church in Johns Creek, GA	http://www.perimeter.org/podcasts/rots/rev2011.jpg
2117	http://opencourtbooks.com/podcasts/feed.xml	Pop Philosophy!	Cindy Pineo	Your regular dose of philosophy from Open Court's Popular Culture and Philosophy series. Get philosophical about your favorite movies, t.v. shows, rock bands, and much more. Download chapters in MP3 format. Visit us at opencourtbooks.com.	http://opencourtbooks.com/images/eye_logo_itunes2.png
2120	http://urpradio.podomatic.com/rss2.xml	"The Urban Renewal Project" CFRO 102.7fm with DJ Sage, 2 Face Al, Big M, and A to the X.	CFRO 102.7fm DJ Sage and host: O-Dog and Big M	We are the largest underground hip hop show on the west  coast of Canada, so expect everything from the latest hip hop tracks to the classics and the rare and obscure; plus giveaways, current events, community info, and special features.	https://urpradio.podomatic.com/images/default/podcast-4-1400.png
2122	http://www.blogtalkradio.com/beverlyhillsrn/podcast	The Beverly Hills RN Show	The Beverly Hills RN Show	Your informative network for everything plastic surgery and more. Access what you need to know from THE Nurse to the Dr. 90210 Plastic Surgeons!	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzLzcxMWEyNWNiLWYyNjctNDJiNy1iZjBlLWI0ZTBlMThhZTE2ZV9uZXdfaGVhZHNob3QuanBn/711a25cb-f267-42b7-bf0e-b4e0e18ae16e_new_headshot.jpg?mode=Basic
2123	http://www.poderato.com/semillabiblica/_feed/1	Ir a www.semillabiblica.org (Podcast) - www.poderato.com/semillabiblica	www.podErato.com	Ir a www.semillabiblica.org	http://www.poderato.com/files/images/28535l16455lpd_lrg_player.jpg
2125	http://feeds.feedburner.com/typisktanders	Anders Josefsson	Anders Josefsson (anders@typisktanders.se)	Poddradio med olika radioprogram och klipp producerade av Anders Josefsson. Prenumerera på podcasten eller lyssna direkt på hemsidan. http://andersjosefsson.se/play	http://media.andersjosefsson.se/andersjosefssonpodcast.jpg
2126	http://thevespers.podomatic.com/rss2.xml	The Vespers' Reason and Rhyme Show	The Vespers	The Vespers podcast: a handful of people hanging out like you would on a front porch solving the worlds problems.	https://assets.podomatic.net/ts/8c/54/2c/brunojones75/3000x3000_10236422.jpg
2128	http://www.teamplayergaming.com/podcasts/TPG_Podcast_Main.rss	TeamPlayerGaming.com	TeamPlayerGaming.com	The players and members of the TPG community talk about the state of TeamPlayerGaming.com focusing on several different topics over the course of the show.	http://www.teamplayergaming.com/podcasts/TPG_Pod.png
2249	http://www.buzzsprout.com/65.rss	Jason Sterling's Sermons - From RUF Ole Miss	Jason Sterling	Add a description here.	\N
2129	https://jr-dawkins-um18.squarespace.com/mtoliveradio?format=rss	Mt.Olive Radio - Mt. Olive House of Prayer	JR Dawkins	This podcast consist of live recordings varing from sermon to songs.	https://images.squarespace-cdn.com/content/5008735ce4b0779c48c7db95/1351295551786-NBHVR3NRTXWBXBGC6C4H/MtOliveHOP.jpg?content-type=image%2Fjpeg
2130	http://feeds.feedburner.com/ChristusVincitPodcasting	cvpodcasting	Brian Michael Page	Podcasting on Roman Catholic Liturgy and Music, by Brian Michael Page, Organist and Music Director at Holy Ghost Church, Tiverton, RI	http://www.christusvincit.net/podcast/podcast144sq.jpg
2137	http://modestomsp.podomatic.com/rss2.xml	Temas católicos: www.padremolleto.blogspot.mx Para el católico practicante.	Modesto Lule	Soy sacerdote misionero. Vivo en México. Sígueme en las redes sociales: http://www.facebook.com/ModestoLuleZ  En esta página subo más podcast: http://www.padremolleto.blogspot.mx/  Gracias por compartir mi página. Todos los comentarios son bien recibidos. Dios te bendiga.	https://assets.podomatic.net/ts/e7/f5/b3/modestomsp/3000x3000_9121826.jpg
2138	http://feeds.feedburner.com/GiTriPodcast	GI Tri Podcast	Gi Tri	We are a club that was created with the beginner triathlete in mind, no cliques, no fuss, just good quality coaching and a great atmosphere	\N
2140	http://pauldotcom.com/podcast/psw.xml	Paul's Security Weekly	Paul Asadoorian (paul@securityweekly.com)	For the latest in computer security news, hacking, and research!  We sit around, drink beer, and talk security.  Our show will feature technical segments that show you how to use the latest tools and techniques.  Special guests appear on the show to enlighten us and change your perspective on information security.	http://static.libsyn.com/p/assets/2/3/1/7/231716b9da792464/PSW_1400x1400.png
2142	http://morristown-green.podomatic.com/rss2.xml	Morristown Green's Podcast	Morristown Green	Podcasts from MorristownGreen.com in Morristown, NJ.	https://assets.podomatic.net/ts/49/d4/4f/morristown-green/3000x3000_2724896.jpg
2143	http://feeds.feedburner.com/Fat2FitHq	Fat2Fit HQ Podcast | Average Guys and Girls Losing Weight, Fat 2 Fit	Firearms Radio Network (jake@firearmsradio.tv)	Here we plan to chronicle our journeys from Fat to Fit. We are helping each other, our listeners and our community to pursue a healthier lifestyle not only in diet, but in all areas of life.	http://www.firearmsradio.net/wp-content/uploads/powerpress/F2FHQ_itunes.jpg
2144	http://feeds.feedburner.com/musicalrantpod	Martin Lucas	Martin Lucas	A tasty podcast of deep / tech house mixes by Martin Lucas, completely free and delivered monthly.	http://dj.martinlucas.co.uk/images/musicalrantpod.jpg
2149	http://hanshotfirst.podomatic.com/rss2.xml	Han Shot First: The Star Wars Original Trilogy Podcast	Ben the Hutt	HAN SHOT FIRST! A podcast for all things Star Wars that don't involve special editions and prequels. Listen to Ben the Hutt and Ty the Wookie interview guests and rant and rave against the evils of Lucasfilm.	https://hanshotfirst.podomatic.com/images/default/podcast-1-1400.png
2150	http://www.cadenaser.com/rssaudio/ser-malaga.xml	SER Malaga	Cadena SER	Una selección de los mejores contenidos de SER Málaga	https://cadenaser.com/estaticos/recursosgraficos/podcast/ser_malaga_1400x1400.jpg
2151	http://feeds2.feedburner.com/WfiuMovies	WFIU: Movies	aschweig@indiana.edu (Movies – Arts and Music)	Arts interviews, reviews, and features from WFIU Public Media from Indiana University.	http://wfiu.org/podcasts/images/arts/category-graphic-movies_sm.jpg
2153	http://spinboyz.podOmatic.com/rss2.xml	SPINBOYZ LATE NIGHT SESSIONS Podcast	SpinBoyzMusic	Mixes that have been done by us at gigs.	https://spinboyz.podomatic.com/images/default/podcast-3-1400.png
2154	http://rss.dw-world.de/xml/DKpodcast_dwn3_pt	Deutsch - warum nicht? Série 3 | Aprender alemão | Deutsche Welle	DW.COM | Deutsche Welle	Alemão avançado: acompanhe as aventuras do estudante Andreas e de sua misteriosa amiga Ex. Gramática: pretérito imperfeito, orações subordinadas, declinação dos adjetivos. [versão em português]	https://static.dw.com/image/17054269_7.jpg
2156	http://supraphonline.podomatic.com/rss2.xml	SUPRAPHON Podcast	SUPRAPHON a.s.		https://assets.podomatic.net/ts/aa/3e/60/35475/1400x1400_8401629.jpg
2158	http://feeds.feedburner.com/FreshLifeChurch	Fresh Life Church	Pastor Levi Lusko (info@freshlifechurch.com)	This is the podcast of the teachings of Fresh Life Church in Kalispell Montana with Pastor Levi Lusko. they are simply messages from the Word of God, real. relevant. raw.	https://feedburner.google.com/fb/images/pub/fb_pwrd.gif
2161	http://www.sireagle.com/podcasts/NoIdea/RSS_Files/NoIdeaPodcast-EpisodeOne_v4.rss	No Idea Podcast - Meet the Guys	Josh Murphy	Welcome to the Blogging home of the No Idea podcast. We are currently in production of our first few Podcasts. We hope to get the published to the iTunes store very soon. We will let you know as soon as we have it posted. Look for our Podcast in the iTunes Store	http://www.sireagle.com/podcasts/NoIdea/Graphics/NoIdeaPodcastGuys300x300v4.jpg
2163	http://housefromitalyvideo.podomatic.com/rss2.xml	House From Italy : The Video Podcast	Dj Alex Zi	Apparte i podcast audio di House From Italy escono anche quelli video! Buona Visione By Dj Alex Zi	https://assets.podomatic.net/ts/5c/d2/33/podcast85010/3000x3000_4560722.jpg
2165	http://sermon.net/rss/FridayNightFire/main	FNF - Young Adults Ministry	Bill Cropper (podcasts@subsplash.com)	Friday Night Fire is a young adult ministry (Ages 18-28) of the Uprising Church in Hebron, MD that is focused towards reaching, discipling, and sending the young adults on the east coast of MD. We leave the denomination at the door, we leave the judging to the judge, and we have a blast living for the reknown of Christ.	\N
2166	http://www.moterrific.com/moterrificrss.xml	Moterrific	Cristi Farrell	Two women who though the motorcycle podcast world lacked a certain opinion, ours. Join us every couple of weeks, or when our real lives allow us to talk about motorcycles	https://images.squarespace-cdn.com/content/56f02f7f2fe131bef53c243c/1460604637128-QH6NIZNPYL1ZRCX1NBL5/image.jpg?content-type=image%2Fjpeg
2167	http://sermon.net/rss/fpcma/main	First Presbyterian Church of Mt. Airy	Steve Lindsley	First Presbyterian Church of Mt. Airy	http://storage.sermon.net/ddbe0930b5979db755cf67ed9a6b69f6/5f96a85a-0-0/content/media/common/artwork/SN-default-1400x1400.png
2755	http://mnhag-al-sunnah.podomatic.com/rss2.xml	مـنـهـاج الـسـنـة	فتى الإسلام		https://assets.podomatic.net/ts/09/c5/c1/mnhag-al-sunnah/1400x1400_3553238.gif
2173	http://propertytalk.podomatic.com/rss2.xml	realestate.com.au's Property Talk	propertytalk	Our real estate experts will attempt to demystify some of the real estate industry's more complex issues, covering topics from: How much you can afford, Auction Day tips and techniques, to the state of the market and investing in property.	https://propertytalk.podomatic.com/images/default/podcast-2-3000.png
2175	http://www.juanprada.com/funlab/podcasts/voidsessions/feed.xml	Void Sessions Mixed by Juan Prada	Juan Prada	A collection of fine electronic music sets. Look for our Podcast in the iTunes Store.[v21-si_d]	http://www.juanprada.com/funlab/podcasts/voidsessions/res/itunesimage.jpg
2177	http://www.blogtalkradio.com/solutionzlive.rss	The Game Changer	GameChangerNetwork	Game changing ideas for executives	https://dasg7xwmldix6.cloudfront.net/hostpics/retina/0de1e836-bd3c-4437-a52d-85446baba072_gcn_btr.jpg
2178	http://hermetic.com/tctc/rss2.xml	Thelema Coast to Coast	John L. Crow	A series of interviews and commentaries about the current state of the occult communities, especially concentrating on Thelemic organizations, Thelemic practitioners and writers, as well as books and other resources of interest to Thelemites and occultists. Thelema Coast to Coast: Occultism Without Apologies.	http://hermetic.com/tctc/tctcitunesicon.jpg
2179	http://feeds.5by5.tv/frequency	Killing Time	Haddie Cooke and Dan Benjamin	Each week join Haddie and Dan for Killing Time where they’ll be talking about everything you’d rather be reading, laughing, Googling, and looking at when you should be working, sleeping, or just paying attention.\n<a href="https://patreon.com/killingtime">This is a fully listener supported show, and only exists with your help. Please support the show on Patreon.</a>	https://assets.fireside.fm/file/fireside-images/podcasts/images/9/9caa4cd4-4e6b-4d84-a072-30cc12aca659/cover.jpg?v=1
2181	http://feeds.feedburner.com/wbwalker/Oebx	W.B. Walker's Old Soul Radio Show	W.B. Walker	A weekly podcast featuring music from Americana, Ameripolitan, Roots, Bluegrass, Rock, Folk, Country, Alt-Country, Blues, & Indie artists. Mixed in with the music is commentary about the songs by W.B. Walker.\r\n\r\nHttp://wbwalker.com/	http://wbwalker.com/wp-content/erikajaneart.jpg
2182	http://www.frostyplace.com/podcast-rss.php	老地方冰果室 Podcast	芝廣數位科技	老地方冰果室最新 Podcast 內容	http://www.heyfile.com/icons/fplogo.gif
2183	http://www.voiceamerica.com/rss/itunes/2207	Sharon Kleyne Hour	VoiceAmerica	• Power of Water / Global Warming – New and innovative wellness discoveries to help you and future generations live within our changing dry environment • Global climate change is a WATER (all-natural moisture) crisis that can cause dryness of the skin, eyes and breathing passages, in addition to spreading bacteria, viruses, allergies and numerous dehydration related diseases • Sharon Kleyne believes that each individual has the power to become proactive in maintaining their own health • Sharon and her guests offer simple, logical, do-it-yourself solutions from a non-political, common sense perspective • Weekly shows have featured experts in medicine, pharmacology, health and healing, therapeutic healing research, nutrition, occupational safety and wellness, global climate change and more. The weekly “Power of Water” segment features guests discussing the scientific, recreational and aesthetic aspects of water.	http://www.voiceamerica.com/content/images/station_images/52/iTunes/kleyne-powerofwater.jpg
2184	http://feeds.feedburner.com/TheBi-quarterlyWomensSocialClub	The Bi-Quarterly Women's Social Club	The Bi-Quarterly Women's Social Club	Oh the humanity! The BQWSC is an exciting Montreal podcast (home of the Just For Laughs comedy festival) and an all around funny, nsfw variety hour of strange things and obscene gestures. Dirty jokes abound and you'll laugh out loud as host Chris Wilding openly discusses his sex life, gets into crazy fights with callers and shares his observations on society, love and everything else in between. Look for the funniest comedians, funny clips, perverted/sexy games, political satire, wtf moments, weird stuff, dirty songs, funny pranks and phone calls - it's satire at its finest. BRAVE THE STORM AND SUBSCRIBE TODAY!	http://static.libsyn.com/p/assets/1/e/5/2/1e52ceb510d9b5ca/BQWSCnocohostsGOOD1400.png
2185	http://www.blogtalkradio.com/southeastgreen/podcast	Southeast Green - Speaking of Green	Southeast Green	Need inspiration to stay on the path to sustainability? Then Speaking of Green is place to be.	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzLzQ1MjgwMTMyLTAwZDAtNDcxOC05ZDgwLWI0OGMyNWY1ODk5NF9iZXRoX2J0cl82MDAuanBn/45280132-00d0-4718-9d80-b48c25f58994_beth_btr_600.jpg?mode=Basic
2187	http://recordings.talkshoe.com/rss112081.xml	Marble Operator	rand_althor	A show dedicated to the YouTube series "Marble Hornets". Also, TribeTwelve, DarkHarvest00, and MLAndersen0.    http://www.youtube.com/user/MarbleHornets    http://twitter.com/#!/marblehornets	https://show-profile-images.s3.amazonaws.com/production/2249/marble-operator_1531861988_itunes.png
2190	http://moofl.free.fr/acoustic-ring/podcast.xml	acoustic ring	MoOfL	Quelques chansons simples, une tranche de vie, un son, un air... débuté en 2004 j'ai essayé dans 'acoustic ring' de créer un ensemble de morceaux simples, avec peu d'instruments. j'essaye de l'alimenter dès que j'en sens l'envie.	http://moofl.free.fr/acoustic-ring/acoustic%2Dring.jpg
2192	http://feeds.feedburner.com/FosterPodcast	Foster Parenting Podcast	T & W (info@fosterpodcast.com)	Join foster parents T and W as they discuss foster care. With humor, insight and Christian faith, they share their everyday ups and downs as a foster family hoping to adopt. Get your questions answered about the foster and fost adopt system while following T and W's journey through the process. What's it like to deal with the system? Are all social workers really jaded? How intrusive is it on your life? All these questions and more will be answered from T and Ws real-life perspective. Watch out! You may find yourself thinking about fostering or adopting too! If you're only going to listen to one episode, we recommend Episode 4	http://www.fosterpodcast.com/wp-content/uploads/FPP-itunes-image.jpg
2193	http://sermon.net/rss/c/firstlutheran-paola/main	First Lutheran Church - Paola, KS	Mark Croucher	First Lutheran Church - Paola, KS	http://storage.sermon.net/b1e56267d58dedc31c02710f3e4cbf95/0-0-0/content/media/33490/artwork/33490_77_podcast.jpg
2194	http://www.sakado-ch.or.jp/podcast/index.xml	坂戸キリスト教会	Kunio Otsuka	坂戸キリスト教会は埼玉県坂戸市にあるプロテスタント教会です。坂戸キリスト教会の礼拝説教を毎週配信しています。http://www.sakado-ch.or.jp/	http://www.sakado-ch.or.jp/podcast/images/sakado-ch.jpg
2250	http://feeds.feedburner.com/paperclipping	Paperclipping: Scrapbooking Videos	Noell Hyman (izzy@izzyvideo.com)	Paperclipping is a series of video tutorials for people who love scrapbooking and would like to improve their scrapbooking skills. Noell Hyman breaks down scrapbooking into basic fundamentals and delivers the concepts in an entertaining and educational way.	http://www.paperclipping.com/images/paperclipping-album.jpg
2757	http://www.ctvnews.ca/rss/ctv-question-period-podcast-1.1132711	.	Evan Solomon		\N
2195	http://www.teenesteem.libsyn.com/rss	Teen Esteem Council Podcast	Mathew Edvik	Mat Edvik and Summer Morris discuss ways to help teenage girls increase their self-esteem and the level of happiness they are experiencing.\n\n"Mat Edvik has helped me overcome many personal issues over the time I've known him. He has known me at my weakest, most vulnerable state and has been extremely knowledgeable and easy to talk to. I could come to him with anything, whether it be regarding my issues with depression, finding a reason to live, and finding purpose in life. He helped me discover that I was valueable and deserved to live an incredible life."\n            Laura A. \n            San Diego CA	https://ssl-static.libsyn.com/p/assets/1/0/4/a/104a52b87d7fa6a7/600x600.jpg
2197	http://feeds.feedburner.com/JamesWoodcocksBlog	Game & Gadget Podcast	contact@jameswoodcock.co.uk (James Woodcock)	Gaming and technology.  Covering many gaming, retro and tech platforms including those by Microsoft, Sony, Nintendo and portables including iPad, iPhone, Android and more...	https://www.jameswoodcock.co.uk/wp-content/uploads/powerpress/JamesWoodcocksPodcast_2020-542.jpg
2200	http://feeds.feedburner.com/TalklineWithHoppyKercheval-Audio	Talkline with Hoppy Kercheval - Audio	West Virginia MetroNews Network (scott@pikewoodcreative.com)	Talkline is a two hour call-in portrait of West Virginia, conducted by the state's best known broadcaster.	http://www.wvmetronews.com/podcasts/logos/talkline300.jpg
2202	http://www.furledsails.com/rss/podcast.xml	Furledsails podcast	Noel Davis	Sailing Podcast	https://ssl-static.libsyn.com/p/assets/c/e/c/7/cec74f5a804d1212/soapy.png
2203	http://spacesharm.podomatic.com/rss2.xml	Space Sharm El Sheikh From Egypt To Ibiza	Space Sharm El Sheikh	Space Sharm El Sheikh Official Podcast Mixed By Resident DJ's	https://assets.podomatic.net/ts/de/2e/f1/spacesharm/3000x3000_7991358.jpg
2204	http://www.radiantwebtools.com/podcast34593.xml	New Testament Christian Fellowship - 2011 Messages	New Testament Christian Fellowship (NTCF) Manchester, NH	This is the teachings that were given on Sunday mornings at New Testament Christian Fellowship.  We are located in Manchester, NH.	http://www.radiantwebtools.com/thumbnails/82485_1400.jpg
2205	http://feeds.feedburner.com/barcelone-audioguide-gratuit	Barcelone: Audioguide gratuit, echantillon, plan de ville et nouvelles	iAudioguide.com (info@iAudioguide.com)	Voila un echantillon d'un iAudioguide de Barcelone. Sur notre site web www.iAudioguide.com vous pouvez telecharger les reste de l'audioguide gratuitement ainsi qu'un plan de ville a utiliser avec votre iPod. Vous y trouvez egalement des liens vers une dizaine d'autre audio guides gratuits, entre autre pour Londres, Rome, Paris.	http://www.iaudioguide.com/images/ituneslogo.jpg
2206	http://network.absoluteradio.co.uk/core/podcasts/rss.php?meta=293	Johnny Vaughan on Absolute Radio	websiteadmin@absoluteradio.co.uk (Absolute Radio Webmaster)	Johnny Vaughan joined Absolute Radio for the duration of the Olympics. Broadcasting live from BT London Live in Hyde Park every day. He had live music, guests, competitions and fun and you can have it in your pocket right now! Get more at www.absoluteradio.co.uk	http://podcast.timlradio.co.uk/johnny_vaughan/johnny_vaughan_lrg.jpg
2207	http://www.bankinfosecurity.com/itunes_rss_podcasts.php	Banking Information Security Podcast	BankInfoSecurity.com	Exclusive, insightful audio interviews by our staff with banking/security leading practitioners and thought-leaders	https://0267f973c7f511eda6a4-193e28812cee85d6e20ea22afb83e185.ssl.cf1.rackcdn.com/itunes-bis.png
2210	http://besser-geld-verdienen.podspot.de/rss	Der Besser-Geld-Verdienen Podcast	MPM GmbH - Besser Geld Verdienen	In diesem Podcast lernen Sie, was Sie wissen müssen, um im Internet erfolgreich Geld zu verdienen. Insider Tricks vom Profi rund um das Thema Internet-Marketing.	\N
2211	http://askdrfritz.libsyn.com/rss	The Get Optimal Network	Fritz Galette	This program examines important topics and issues impacting all of us through the lens of health and wellness.  The program highlights the questions, challenges and struggles people typically face in everyday life. During each program we clarify the issues and provide useful information, pragmatic tips, and resources.	https://ssl-static.libsyn.com/p/assets/d/a/8/5/da85ce57b42db13f/getoptimal.jpg
2212	http://sc1.podOmatic.com/rss2.xml	62 db / SC1~MIXES	sC1 / Spaze Crafte One	DJ ESCE creates an eclectic & experimental blends via ambient soundscapes, minimal tek house, hip hop, grime, glitch, dubstep, drum & bass, live instrumentation & alien magic dust...\n\nAll in the purpose of making you:\n\n1. SHAKE yo bum!\n2. RATTLE the bass bins!\n3. ROLL what you got!\n4. contemplate life\n5. meditate\n6. medicate\n7. feel yo' self\n\nenjoy &\nblessingz!!!	https://assets.podomatic.net/ts/a6/93/ea/sc1/3000x3000_606259.jpg
2213	http://www.blogtalkradio.com/fit4life.rss	Living the Fit Life!	Archive	Fit4Life Radio showcases individuals who were once unhealthy but have now committed to living the Fit Lifestyle.<br /><br />In addition, we will also bring valuable fitness and weight management information to you each week. So even if there is not an in-studio guest, you will be inspired to get on the FitTrack and stay there!	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/b57fa5c07301c085770359d4e373fa0a.jpg
2214	http://www.gracecathedral.org/mp3/sermon/sermon.xml	Sermons from Grace Cathedral	Grace Cathedral	Sunday Sermons from San Francisco's Grace Cathedral, home to a community where the best of Episcopal tradition courageously embraces innovation and open-minded conversation. At Grace Cathedral, inclusion is expected and people of all faiths are welcomed. The cathedral itself, a renowned San Francisco landmark, serves as a magnet where diverse people gather to worship, celebrate, seek solace, converse and learn.	https://ssl-static.libsyn.com/p/assets/a/8/7/3/a8735481fc02669d/sermons-1400x1400.jpg
2215	http://kardioblog.podomatic.com/rss2.xml	Kardiopodcast	Jan Štros		https://assets.podomatic.net/ts/95/a6/1e/94344/3000x3000_10027802.jpg
2216	http://feeds.feedburner.com/MitoActionpodcast	Audio Podcast	MitoAction	The official MitoAction podcast is a monthly call often with physicians who are experts on mitochondrial disease.  Mitochondrial disease occurs when the mitochondria(the powerhouse of a cell) are unable to effectively generate energy during food metabolism.  Approximately one in 4000 adults and children have mitochondrial disease ("Mito").  MitoAction is a non-profit organization dedicated to support, education and advocacy for the mitochondrial disease patient community.	http://www.mitoaction.org/files/podcasts/logo.png
2295	http://itstreaming.apple.com/podcasts/podcast_team_test/hp/bd.xml	emtTEST	EMT Inc.	You don't want to subscribe to this podcast.	http://itstreaming.apple.com/podcasts/podcast_team_test/hp/cover_art.jpg
2296	http://feeds2.feedburner.com/meneameland320	meneameland (320x180)	meneameland	Podcast semanal para pasar el rato	http://meneameland.com/logosjai/meneitunes05x140.png
2218	http://www.spacemusic.nl/podcast/freshairlounge/freshairlounge.xml	Fresh Air! Lounge Series	Fresh Air! Lounge Series	Lounge, downtempo, chillout time... It's electronic and acoustic music from all over the world! Spacemusic.nl presents the best chillout music, a cool blend of Summer, Sun, Beach and no worries. Exclusive (first hand) releases right here on the podcast ::: Featuring artists like Michael E., Afterlife, Aware, Iëlo, Late Night Alumni, Lazy Hammock, Musetta, Shine, Kalabi, Riccardo Eberspacher, Bondi Chill, Stockfinster, Henrik Takkenberg, Evolve, Code314, Acidhead, Sine, Polished Chrome, Ensoul, Schiller, Jean Mare, Dave Jerome, Fluff, Alexel, Clarisse Albrecht, Merge of Equals, Mindsoup, DigiTube, Sunburn in Cyprus, Goldlounge, Triangle Sun, Klangstein, Mandalay, Gaelle, Frank Borell, Samantha James, Dash Berlin, Goldfrapp, The Velvet Lounge Project, Charlie North, William Orbit, Steve Osaka, Desa Systems, Dulac & Dubois, Dinka and many others………….. Tune in, we're waiting for you!	http://www.spacemusic.nl/podcast/ituneslogos/freshair-1400.jpg
2220	http://feeds.feedburner.com/KatholischePredigten	katholische Predigten	Bresser (bruderschaft@peripsum.de)	katholische Predigten u.A. von Pfr. Pietrek, CM	http://www.per-ipsum.com/images/podcasts/4l.jpg
2221	http://radiofrance-podcast.net/podcast09/rss_12360.xml	La Grande table	France Culture (podcast@radiofrance.com)	A l'heure du déjeuner, les convives - artistes, personnalités du monde de la culture et des idées - prennent place à table. Du lundi au jeudi \nde 12h0\n0 à 13h30.	https://cdn.radiofrance.fr/s3/cruiser-production/2020/09/16ff54ba-251b-40a7-893f-7896c8d3b548/1400x1400_rf_omm_0000026543_ite.jpg
2223	http://mrhonsberger.podomatic.com/rss2.xml	Welcome to Mr. Honsberger's Class!	Mike Honsberger		https://assets.podomatic.net/ts/b9/6c/d2/mrhonsberger/1400x1400_601504.jpg
2224	http://www.t-shops.co.uk/poll/hidden/podcasting/rlm.xml	RadioLeMans.com	Radio Show Ltd.	Podcasts from RadioLeMans.com, including coverage of races from the FIA World Endurance Championship (WEC), European Le Mans Series (ELMS), VLN, WeatherTech Sportscar Championship, Hankook 24 Hour Series and of course the Le Mans 24 hours. Plus other great endurance racing from around the world. In addition there's the weekly motorsport magazine show Midweek Motorsport, in depth interviews with motor racing's biggest names, and behind the scenes looks at teams and manufacturers. Check out RSL's other podcast feeds, for Midweek Motorsport, Real World Road Tests, Tyler's Long Ones and The TORA Radio Show.	http://www.t-shops.co.uk/poll/hidden/podcasting/rlm_ilogo.jpg
2226	http://bombventure.podomatic.com/rss2.xml	Jay Ro's Bombventure	Jay Ro	http://facebook.com/bombventure\nhttp://soundcloud.com/j-roooo\njayrodj@gmail.com	https://bombventure.podomatic.com/images/default/podcast-3-1400.png
2227	http://totalcar.hu/egester/rss/podcast	Totalcar Égéstér: Podcast autókról	Totalcar	Hangos Totalcar (http://totalcar.hu/egester) minden csütörtökön. Kereke van és motorja? Mi megemésztjük!	https://totalcar.hu/assets/images/egester_podcast.jpg
2234	http://feeds.twit.tv/specials_video_large	TWiT News (Video)	Leo Laporte	When tech news breaks, we cover it. On this podcast, you'll get the latest product announcements from all the tech giants, plus breaking tech news as it happens. Join Leo Laporte, Jason Howell, Mikah Sargent, Ant Pruitt, and other TWiT hosts on the TWiT News podcast.\n\nEpisodes available at https://twit.tv/shows/twit-news	https://elroy.twit.tv/sites/default/files/styles/twit_album_art_2048x2048/public/images/shows/twit_news/album_art/hd/twitnews_albumart.jpg?itok=GbqLG6GH
2235	http://feeds.feedburner.com/macosxscreencasts_podcast_deutsch	Mac OS X Screencasts » Deutsche Videos	Andreas Zeitler	Deutsche Screencasts zu iOS und OS X.\n\nInfos:\nMac OS X Screencasts kreeirt Tutorials, Software Reviews gebündelten mit Gewinnspielen und Rabattaktionen für alle möglichen Mac und iOS Apps.\nBesucht uns doch einfach auf unserer Homepage unter: www.macosxscreencasts.de\n\nToller Bonus: \nUnsere Screencasts werden in hoher Qualität aufgenommen! Dies bedeutet leider, dass manche Videos auf iPhone oder iPod Touch Geräten nicht abspielbar sind.	http://files.macosxscreencasts.com/feed/MOSXLogo4.png
2236	http://rss.dw-world.de/xml/podcast_world-in-progress	World in Progress | Deutsche Welle	DW.COM | Deutsche Welle	News, Analysis and Service from Germany and Europe - in 30 Languages	https://static.dw.com/image/2380459_7.jpg
2238	http://www.fpccarsoncity.org/feeds/sermons	Sermons	First Presbyterian Church of Carson City: Carson City, NV	Sermons	https://www.csmedia1.com/fpccarsoncity.org/itunes-logo.png
2239	http://www.clutterfreeservices.com/Podcast/feed.xml	The Heart of Organizing	Andrew Hartman	Welcome to the Heart of Organizing.  In this podcast, the word "heart" has two meanings.  First, as in the "heart of the matter," it means the most central and important part.  Second, it is a compassionate and non-judgmental approach to organizing.  It’s an approach that \ncomes from the heart and empowers you to have a better life.\n\nJoin Andy Hartman as he shares insights from his eleven years of experience as a Professional Organizer.	http://www.clutterfreeservices.com/Podcast/hooimage.jpg
2240	http://luism.podOmatic.com/rss2.xml	Luis M's Podcast	Luis M		https://assets.podomatic.net/ts/01/a2/50/luism/1400x1400_8145682.jpg
2242	http://toginet.com/rss/itunes/sextalkwithlou	Sex Talk with Lou	Lou Paget	Lou interviews Dr.Charles Runels about The O Shot procedure.  Based on Platelet Rich Plasmapheresis (PRP) therapy this is a revolutionary way to improve women's continence and orgasmic response.  Technically the O Shot initiates the growth of new tissue in the clitoris, pubococcygeus muscle that is the muscle that contracts during orgasm, upper vaginal vault and surrounding tissue.  We discuss best uses for this PRP procedure and specifically how it is done.  We discuss the damage and problems with Laser Vaginal Rejuvenation therapy, neither rejuvenating or therapeutic.	https://toginet.com/showimages/sextalkwithlou/STWLiTunes.jpg
2243	http://fortressoffaith.sermon.tv/rss/main	Fortress of Faith - Daily	Tom Wallace	Resisting Islam - Rescuing Muslims - Reviving North America	http://storage.sermon.net/0855a60564ca567882bdfc753af0c431/0-0-0/content/media/23185/artwork/4e05c5a03f197be7dc152f2f244284cf.png
2244	http://tottenhampn.podbean.com/feed/	Tottenham Podcast Norge	Hans Fredrik og Åsmund	Verdens første og siste, beste og verste Tottenham Hotspur podcast på norsk!!	http://tottenhampn.podbean.com/mf/web/kpxurr/tottenham.jpg
2245	http://podaholics.com/category/podcasts/ne-hip-hop-show/feed/	Paw’daholics	\N	Where Pets Are All The Chatter	https://podaholics.com/wp-content/uploads/2020/01/cropped-podaholics-icon-32x32.png
2246	http://hawaiianconcertguide.com/rss	Hawaiian Concert Guide	Piko	A weekly podcast featuring Hawaiian artists and halau performing off-island and around the world.	https://ssl-static.libsyn.com/p/assets/6/2/2/e/622e405bfb41aa57/hcg_sqr_1600x1600.jpg
2248	http://www.strangeassembly.com/podcasts/strange_assembly.xml	Strange Assembly - Tabletop Gaming Podcast	Strange Assembly	Strange Assembly covers and reviews every sort of tabletop gaming - board games, card games, and RPGs.	https://www.strangeassembly.com/podcasts/PodcastLogo.jpg
2254	http://www.therestofeverest.com/feed/the-rest-of-everest-3d-anaglyph/	The Rest of Everest 3D (Anaglyph)	jon@therestofeverest.com (Jon Miller)	An Almost Unabridged Expedition Experience--Now In 3D.<br />\n<br />\nHigh Definition anaglyph format for viewing with standard red/blue glasses.<br />\n<br />\nStereoscopic 3D footage from Season 5 of The Rest of Everest. This podcast simply augments the main podcast feed. If an episode from Season 5 contains 3D material--not all do--then it will end up here in it's entirety.<br />\n<br />\nFor more information on The Rest of Everest, please visit http://www.therestofeverest.com	http://www.therestofeverest.com/Images/Rest-of-Everest-Logo-3D-Anaglyph-1400.jpg
2256	http://www.callthecow.com/cowcast.xml	Apocalypse Cow Music Licensing	Apocalypse Cow	Apocalypse Cow Productions: Songs available for immediate music licensing.  Everything from Modern Rock, Retro, Orchestral, Punk, Electronica, Instrumental Themes, Holiday, Jazz and oh, so much more.	http://www.callthecow.com/images/PodcastCow.jpg
2257	http://dontbeasalmon.net/embryology-rss.xml	Swansea University College of Medicine: Anatomy and Embryology	Dr Samuel Webster	A series of human embryology and anatomy podcasts linked to the teaching at the Swansea University School of Medicine, but hopefully helpful to all medical students.	http://scs.swan.ac.uk/media/podcast/embryology/14wk_scan.jpg
2258	http://shaunbangerscott.podOmatic.com/rss2.xml	SHAUN BANGER SCOTT presents	SHAUN BANGER SCOTT	Shaun Banger Scott and his Sidekicks Snaggle and a stray Ginger they found on there travels... take you on a weekly journey of all the best upfront Bass driven house music around with a touch of EDM. \nTweet  @shaunbscott	https://assets.podomatic.net/ts/17/19/5a/shaunbangerscott/3000x3000_8964527.jpg
2261	http://feeds.feedburner.com/metsblogpodcast	Shea Anything	Shea Anything	<p>Baseball Night in New York host Doug Williams, SNY MLB Insider Andy Martino, and SNY Analyst and Mets legend Keith Hernandez bring you the Shea Anything podcast! The guys discuss and debate everything surrounding the New York Mets, with two editions weekly to provide the ultimate fan with insider access, exclusive interviews, and unique stories about the team from Queens.</p>	https://content.production.cdn.art19.com/images/e3/77/a7/1d/e377a71d-27d8-484b-ae83-98ce43b489c5/e771e53cd720269b6f658dbe2b612ff3672c77d9becebde100a22ef083ca77c11af15e8749258b6d2e9582082695d435a90f6404eb8daa9a523d0fe39bd095b2.jpeg
2264	http://librivox.org/rss/7574	Wish, The by COWLEY, Abraham	LibriVox	LibriVox volunteers bring you 13 recordings of The Wish by Abraham Cowley. This was the Fortnightly Poetry project for February 24, 2013. Abraham Cowley (/ˈkuːli/) was a leading English poet in the 16th century. (Summary by David Lawrence)	\N
2265	http://lemileoncdc2012.podomatic.com/rss2.xml	RADIO LICORNE	Radio Licorne	Cette année, le son radiophonique s’intègre 24h/24 à la Course du Coeur. La "Radio Licorne" sera animée par 3 VéloCarreporters, 2 correspondantes terrestres, 1 Ingénieur backstage et tous les acteurs de la CDC 2012. \nUne couverture nationale pour un événement planétaire. 4 jours 4 nuits pour faire courir la vie, 4 jours 4 nuits pour être au coeur la course.	https://assets.podomatic.net/ts/a2/14/01/contact81273/3000x3000_14690376.jpg
2266	http://feeds.feedburner.com/ThePopCulturePulpit	The Pop Culture Pulpit	Eric Bramlett (popculturepulpit@gmail.com)	Eric Bramlett, Creative Arts Director and Court Jester at COMMUNITY Christian Church, gives “need-to-know” info on pop culture to help pastors get a leg up on latest trends and culture shifts.	http://popculturepulpit.podbean.com/mf/web/kmeinv/PopCultureBlack512.jpg
2269	http://www.blogtalkradio.com/mitchell-productions.rss	The Sharvette Mitchell Radio Show	Sharvette Mitchell Radio Show	Tuesday at 6:00 p.m. EST | The Sharvette Mitchell Radio Show, brought to you by Mitchell Productions, LLC, features various guests that include, celebrities, ar	https://dasg7xwmldix6.cloudfront.net/hostpics/retina/fe6451c2-576f-42cc-9500-f2f70d99fa5a_podcast.jpg
2270	http://view.guttertrash.net/feed/podcast/	The View Masters	eshonborn@gmail.com (Eric Shonborn, Joe Grunenwald)		http://view.guttertrash.net/art/view-itunes.png
2274	http://feeds.feedburner.com/SlateNegotiationAcademy	Slate's Negotiation Academy	Slate Magazine/Panoply	A series of short podcasts that reveal the secrets of everyday haggling, whether you’re negotiating in the board room or your child’s bedroom. Part of the Panoply Network.	https://images.megaphone.fm/w5KSwktLgjJtdzujjCqGvRHfif1y85sCKAvp5puPRQw/plain/s3://megaphone-prod/podcasts/69e50668-df35-11e5-a4a3-37cad831416d/image/1400x1400_Panoply_negotiationAcademy.jpg
2276	http://v4e.podomatic.com/rss2.xml	Vietnamese for Everybody's Podcast	Vietnamese 4 Everybody		https://assets.podomatic.net/ts/3d/16/b3/qualityeslclasses/3000x3000_5011166.jpg
2277	http://www.truenorthchurch.net/feeds/sermons	Audio Archive	Allan Whitlinger	Audio Archive	https://www.csmedia1.com/truenorthchurch.net/dfv3kgdb_34hrjhv6f7_b.jpg
2279	http://feeds.feedburner.com/chosenym	Chosen Youth Ministries	Chosen Youth Ministries (noreply@blogger.com)	Messages by Deb Graper from Chosen Youth Ministries Peru, IL	http://i13.photobucket.com/albums/a278/3030303/cym-ad-1.jpg
2281	http://feeds.feedburner.com/pocinema	QB Training information	Eu Assisti e você?	O podcast do site,Eu assisti e você?	http://euassistievoce.files.wordpress.com/2013/07/mini-claquete.jpg
2289	http://www.mchenryalliance.com/mp3s/ABC.rss	Alliance Bible Church Sermon Audio	Kary Olsen	Alliance Bible exists to shine a light on God's message to everyone.  Our SERMON AUDIO podcast feed spotlights our senior Pastor Paul Martin and featured guests.  Our prayer is that you will be encouraged in your faith as you listen.	http://www.mchenryalliance.com/images/ABC.jpg
2290	http://hijackedheadspace.libsyn.com/rss	Hijacked Headspace	George Shantz and Jamie Merkel	The Cannabis Podcast for #yeg and the rest of Canada! Tune in for weekly strain reviews and up-to-date news about the journey to legalization.	https://ssl-static.libsyn.com/p/assets/d/f/1/7/df173848e59f7ac5/NEW-Hijacked_Headspace_Logo-RGB.jpg
2297	http://podcast.rthk.org.hk/podcast/traveleye.xml	香港電台︰文化旅遊	RTHK.HK	岑逸飛的文化旅遊不只是吃喝玩樂，還有研究地貌及遊博物館；聽他的旅遊心得、趣事和感想，你定能體會當地風土人情。	http://podcast.rthk.hk/podcast/upload_photo/item_photo/1400x1400_48.jpg
2298	http://feeds.feedburner.com/HermanLindqvist-LevandeHistoria	Herman Lindqvist - Levande Historia	Aftonbladet (bjarne.frykholm@aftonbladet.se)	Hör Herman Lindqvist berätta om historiska händelser. Följ podcasten som komplement till Aftonbladets bilaga Levande Historia.	http://wwwc.aftonbladet.se/download/mobi/podcast/herman-levande-historia_144.jpg
2299	http://gc2006.podspot.de/rss	Rob Bubble´s Games Convention Podcast	Robin Blase	Der Games Convention Podcast, ein ableger von Rob Bubble´s Gameshow, ist ein wärend der GC täglich live vom Messegelände erscheinender Podcast , gemacht von "einem Gleichgesinnten Zocker", gemacht von einem gnadenlosen Spieletester, der jungen Gamern die neusten Neuigkeiten der Spielewelt mitteilt und Spiele sowie Hardware beurteilt und zwar nicht weil es sein Beruf ist oder er von den Herstellern Geld bekommt, sondern weil er selber leidenschaftlicher Zocker ist. Spielehersteller sollten sich warm anziehen: Rob Bubble nimmt aktuelle Games auseinander - ohne Rücksicht auf Verluste!\r\nIn Rob Bubble´s Games Convention Podcast, bekommst du Infos über Games die erst in Monaten rauskommen!	\N
2300	http://www.islamhouse.com/pc/327408	Një buqetë me këshilla!	IslamHouse	Kjo është një buqetë me këshilla që janë ndihmë për çdo besimtar në rrugën e kësaj bote. Këto porosi dhe këshilla janë nga më të ndryshmet duke filluar nga: qëllimi i muslimanit në jetë –  e që është arritja e kënaqësisë së Allahut, pastaj rëndësia e drejtësisë, marrja me çështjet që janë në interes së tij dhe jo çështje të tjera, si dhe shumë këshilla të tjera të formuluara në mënyrë të bukur, të thjeshtë dhe tërheqëse.	http://islamhouse.com/islamhouse-sq.jpg
2305	http://feeds2.feedburner.com/LinebergersPodcast	Lineberger's AP Lit	Jason Lineberger	The published projects of my classes, from 10th grade English to AP.	http://lineberger.edublogs.org/files/2008/11/cropped-100_0712.jpg
2306	http://fp2kyu.seesaa.net/index20.rdf	FP3級・2級 合格（過去問対策）講座	ＦＰ佐久間事務所	FP２級の短期合格を目指す方々のために、過去問試験を中心に攻略のポイントを解説する試験対策講座です。 FP佐久間事務所の「CD・DVD講座」もぜひご活用ください。 ビジネス対談番組「FPと語る－聞いて得するお金の話」もお聞き逃しなく。	\N
2307	https://sakai.unc.edu/podcasts/site/26aca13d-88ef-4f22-8e77-caf66b34039f	CC-CPG's official Podcast.	\N	CC-CPG official podcast. Please check back throughout the semester for updates.	\N
2308	http://sportsusnews.podOmatic.com/rss2.xml	The Impact Sports Hour	The Impact Sports Hour	Welcome to the high impact sports hour where we talk about the week that was sports. Join us every Wednesday at 7 pm Eastern on blogtalkradio.com. You can call in or email us at impactsportshour@gmail.com	https://assets.podomatic.net/ts/f4/bf/d1/sportsusnews/3000x3000_3412667.jpg
2309	http://feeds.feedburner.com/Nerdflix	NerdFlix Podcast	Mikey Symons, JM Thomas, Austin Kent	Nerds talking about movies?  Has Christmas come early?	http://i1083.photobucket.com/albums/j393/nerdflix/f5dfr.png
2311	http://media.afterbuzztv.com/category/abtv_osw/feed/	Comments on:	\N	The Worldwide Leader in TV Discussion	\N
2312	http://feeds.feedburner.com/PhilipBanse	Philip Banse - Podcast	Philip Banse	Hier veröffentliche ich Interviews, Vorträge und ausgewählte Radiobeiträge. Alle anderen Podcasts findet Ihr unter im Kuechentsud.io.	http://philipbanse.de/foto/Banse-sw-quadrat.jpg
2314	http://podcast.rthk.org.hk/podcast/seaworldodyssey_i.xml	香港電台：海底漫遊	RTHK.HK	香港雖然沒有珊瑚礁，但全球800多個珊瑚品種之中，十分之一竟然可在香港找到！這大大小小的珊瑚部落，吸引了300多種珊瑚魚以香港為家！位於香港東面水域的海底竟有一片海葵林，面積足有兩個籃球場般大，連外國潛水員都沒想過在香港可以找到這般大的一個小丑魚樂園！	http://podcast.rthk.hk/podcast/upload_photo/item_photo/1400x1400_120.jpg
2316	http://www.ronne.com/rss/acalto.xml	SHS Acapella Choir Alto Podcast	B Ronne	This is a podcast for choir members at SHS.  This podcast will contain rehearsal tracks for the alto section.	http://www.ronne.com/rss/image.jpg
2319	http://toginet.com/rss/itunes/xlibrisonair	Xlibris On Air	Toginet Radio	Xlibris On Air...get the story behind the story on fiction and literature, thrillers, children's books, mystery and crime novels, romance, science fiction and fantasy, westerns, history, humor, inspiration and so many more topics. It's all on Xlibris On Air. You'll get to hear the authors talking about their books. Take the opportunity to hear the insights on what inspired them to write it. Join J. Douglas Barker every Sunday at 12:00-1:00PM EST to hear the latest interviews by today's authors!	https://toginet.com/showimages/xlibrisonair/XlibrisThumb.jpg
2326	http://feeds.feedburner.com/IfThereIsHellBelowPodcast	If There Is Hell Below... Arkive	If There Is Hell Below	If There is Hell Below (est. 2010) is a weekly new music podcast presented by two best pals Rob Morgan and Callum Eckersley. Each week they bring in 12 new tracks, have a few beers, chat about their favourite finds of the week and joke about life.\r\n\r\n'On the Ark with…' is a brand new podcast from the boys who gave you the If There Is Hell Below. \r\nIn each episode Rob and Callum invite one of their favourite artists onto their mythical ark; a huge vessel prepped for the end of the world and with your hosts as Co-Captains they welcome their new ship mates. \r\n\r\nOver drinks they ask the people who make the music what songs and albums have made them the musician, artist and person they are.	https://1.bp.blogspot.com/-0b_7UW2XnQk/X5X6aZipFUI/AAAAAAAAAKc/wnv0eP0jzrkpxZvpcep4K3oHM5AdfvY_gCLcBGAsYHQ/s2048/ITHB%2Blogo%2B1.jpg
2964	http://www.estudosdabiblia.net/rss/rss.xml	Estudos Bíblicos Arquivos de Áudio	Dennis Allan	Arquivos de Audio	http://www.estudosdabiblia.net/images/podcast.png
2327	http://www.heidiandfrank.com/podcast	Heidi and Frank Podcast	Toad Hop Network	Full Podcast of Heidi and Frank that is available at heidiandfrank.com. Please visit http://www.heidiandfrank.com/podcasthelp if you are having problems with the download of this item.	http://images.heidiandfrank.com/images/podcast/HFpodcastartwork_SHOW_AUDIO.jpg
2328	http://feeds.feedburner.com/blogspot/aLvS	arrest	WW Anderson	Daily, the electronic media tells us what to think, and what to think about, and how to think about it. The very semantics of being are dictated by talking heads, the editorial POV of the publication, the filter of politicians and their lobbying bedfellows, all viscerally directed by the American military charged with safeguarding the security 'we hold so dear as truth.' To think, you need to open the mind to YOU. We always refer to our founding fathers,(Emerson, Founding Fathers, & Christopher Reeve) but they may not be the cliches propelled at you by the media, or politicians, but by how and why you think.	http://www.imyim.com/flagx.gif
2329	http://radio.nac-cna.ca/podcast/BaladOCNA/BaladOCNA.xml	BaladOCNA	Canada's National Arts Centre	À chaque épisode, Marjolaine Fournier (contrebasse solo assistant à l'Orchestre du CNA) vous amène en coulisse jeter un regard curieux et parfois incisif sur la vie de tous les jours d'un musicien d'orchestre. Elle s'entretient régulièrement avec des collègues de l'Orchestre et des artistes invités sur une foule de sujets allant des auditions aux tournées internationales.	https://radio.nac-cna.ca/podcast/BaladOCNA/baladOCNA1400.jpg
2330	http://www.sermonize.us/feed/podcast/	Sermonize Us	admin@sermonize.us (Sermonize Us)	brought to you by sermonize.us	http://www.sermonize.us/wp-content/uploads/powerpress/itunes.jpg
2331	http://feeds.feedburner.com/ExploringAmericaAndChildrensLiterature	Exploring America and Children's Literature	Christy G. Keeler, Ph.D.	This podcast was developed as part of an elementary-level Clark County School District Teaching American History Grant. The three-year grant will fund six modules per year with each module focusing on a different era of American history and a different pedagogical theme. This podcast focuses on the the Exploration: From Lewis and Clark to the Gold Rush and Children's Literature. Participants in the grant are third, fourth, and fifth grade teachers in Clark County (the greater Las Vegas area), Nevada. Teaching scholars include Drs. Michael Green and Deanna Beachley of the College of Southern Nevada and Dr. Christy Keeler of the University of Nevada, Las Vegas. As part of this five week module, teachers meet on campus on two occasions and the remainder of their work is completed online. The culminating activity for this module is the development of teaching resources to accompany children's books on U.S. Exploration during the 1800s. Participants will utilize pre-selected children's chapter books appropriate for intermediate-level students for their final project.	http://www.ldsces.org/inst_manuals/chft/images/48-09.gif
2332	http://feeds.feedburner.com/epicbattleaxepodcasts	EpicBattleAxe Podcasts	EpicBattleAxe.com	With our patent-pending blend of irreverent humor and razor-sharp insight, EpicBattleAxe cuts through the crap to deliver the video game news and opinion that matters most. Join us for our weekly podcasts, EpicBattleCry and The Axe Factor, and join Gaming's Most Epic Community!	http://static.libsyn.com/p/assets/c/a/4/4/ca445eb56c2c5abd/eba-podcasts-logo-1400.jpg
2333	http://wakeuplatewithdougieshow.podbean.com/feed/	Wake Up Late with Dougie Show	Dougie Dangerous	Podcast hosted by Dougie Almeida & Jen Hellman along with Special Guests Form the World of Comedy & Entertainment	https://pbcdn1.podbean.com/imglogo/image-logo/525117/wulwds_zoom_logo_63io3.png
2336	http://retro.rnn.libsynpro.com/rss	Retro Old Time Radio		You've just found the Retro Radio Podcast. The Internets best kept secret source of Old Time Radio Comedy. All comedy radio classics for your listening pleasure. Hand picked by Keith, and sometimes by the Retro bots. Tell a friend about us.\n\n We also take requests! If you have a favorite classic radio show, that you would like to hear,\nsend me your request. It doesn't even have to be comedy. If I have it in my collection, I'll play it for you	http://static.libsyn.com/p/assets/d/f/7/b/df7bbb9918cf0064/retrootr.jpg
2339	http://www.skivamusic.com/Seven-Podcasts/sk-infinity-music/sk-infinity-music.php	60 Minutes of Kundalini Meditation Music	Sandeep Khurana	Composed by Sandeep Khurana	http://www.skivamusic.com/Seven-Podcasts/sk-infinity-music/images/itunes_image.jpg
2341	http://femalebodybuilders.podomatic.com/rss2.xml	We Have Moved	femalebodybuilders	We have moved to: http://femalebodybuilders.podshow.com	https://assets.podomatic.net/ts/fb/1c/40/femalebodybuilders/3000x3000_328739.jpg
2345	http://www.comicgeekspeak.com/cgs-gameon-rss.xml	Comic Geek Speak Presents: Game On	Speakers of Geek	Comic Geek Speak Presents: Game On. Most of the crew at Comic Geek Speak are avid board-game players.  In this show we'll be talking a little about some of the newest games we play and any interesting discussion that comes up about old favorites.	http://www.comicgeekspeak.com/images/podcastLogos/cgs_ipod.png
2346	http://sumorecords.podomatic.com/rss2.xml	SUMOrg International(Canada*Japan)est 1984's Podcast	SUMOrg International(Canada*Japan)est 1984(r)	‎~*(((S*U*M*O)))*~ is Society Underground MuZiQue OrganiZation International(Australia*Brazil*Barbados*Cuba*Canada*Denmark*Jamaica*Japan*Haiti*Italy*Mexico*Norway*Panama*Spain*Trinidad*USA*United Kingdom*South Africa & Switzerland)est 1984.Sincerely Lyndon BNP Menard Founder of SUMOrg International & S*U*M*O Rec(est 1984)r	https://sumorecords.podomatic.com/images/default/S-3000.png
2348	http://feeds.feedburner.com/ClopeziTV?format=xml	Clopezi TV (HD)	Clopezi	Video-comentarios en castellano sobre videojuegos	http://www.clopezi.es/podcast/nuevocpztvpeque.jpg
2353	http://overthehedge.wm.wizzard.tv/rss	Over the Hedge Animated Cartoons	RingTales	Over the Hedge is a syndicated comic strip written and drawn by Michael Fry and T. Lewis. It tells the story of a raccoon, a turtle and a squirrel who come to terms with their woodlands being taken over by suburbia, trying to survive the increasing flow of humanity and technology while becoming enticed by it at the same time.	http://static.libsyn.com/p/assets/d/3/e/9/d3e916bd0553969f/hedge_podcast.jpg
2354	http://images.forbes.com/intelligentinvesting/podcast/index.xml	Intelligent Investing With Steve Forbes	Steve Forbes (itunes@exchange.forbes.net)	Steve Forbes hosts a weekly, half-hour uninterrupted interview program with the best minds in business.  The thoughtful, long-form show with influential and insightful guests includes the best market strategists, forecasters and money managers from Wall Street and beyond.	http://images.forbes.com/media/columnists/steveforbes_600x600.jpg
2355	http://podcast.uctv.tv/uctv_religion.rss	Religion and Spirituality (Audio)	UCTV	Americans enjoy a multiplicity of religious traditions. Explore both traditional religions, and what it means to be spiritual in a rapidly changing and diversifying religious world.	https://www.uctv.tv/images/podcastlogos/300x300_RegardingReligion.jpg
2357	http://bandofbadgerspresents.podomatic.com/rss2.xml	Band of Badgers Presents...	ROBERT POWELL	Band of Badgers Presents aims to introduce you to some great music from talented bands and artists out there on the independent music scene today.\n\nThere will also be talk about gigs and festivals and if you're lucky there may be a few asides which it will be my mission to make at least a little bit funny. Please give me time!\n\nAll in all Band of Badgers Presents endeavours to bring you a playlist that will inspire you to check out the featured artists further.	https://bandofbadgerspresents.podomatic.com/images/default/podcast-4-3000.png
2358	http://recordings.talkshoe.com/rss97564.xml	The Gathering Oasis	thegatheringoasis1	Visit www.thegochurch.com for more information.	https://show-profile-images.s3.amazonaws.com/production/2091/the-gathering-oasis_1561953157_itunes.png
2360	http://rss.dw-world.de/xml/podcast_tomorrow-today	Tomorrow Today: The Science Magazine	DW.COM | Deutsche Welle	Dive in to the fascinating world of science with Tomorrow Today. Your weekly dose of science knowledge. A show for everyone who's curious -- about our cosmos and how it works.	https://static.dw.com/image/43844311_7.jpg
2361	http://www.partytime.fr/podcast/dubmecrazy/dircaster.php	Dub Me Crazy Radio Show	Party Time	3 hour live show with Legal Shot sound from Rennes/France - Dub, digital, UK roots	https://images.partytime.fr/logos/NewBanniere2011WEB.jpg
2363	http://nt-itunesu.s3.amazonaws.com/alan-bennett-reads-his-introduction-to-people.xml	Alan Bennett reads his introduction to People	Michael Peers	Alan Bennett reads the introduction to the playscript of People as well as a poem by Philip Larkin, entitled The Explosion.\n\nThis is a recording of a live Platform event from November 2012.	http://nt-itunesu.s3.amazonaws.com/alanbennettpeoplepodcast.jpg
2367	http://feeds.feedburner.com/hope4macomb	hope4macomb	Hope Community Baptist Church (media@hope4macomb.com)	hope4macomb podcast - a ministry of Hope Community Baptist Church in Sterling Heights, MI	http://www.hope4macomb.com/images/podcast.png
2368	http://feeds.twit.tv/natn_video_large	net@night (Video)	Leo Laporte	Live from Canada, California, and around the world... What's happening on the 'net right now? Amber MacArthur spends every waking moment combing the net for cool sites, viral videos, and funny and moving moments online and she shares them with us every week.\n\nAlthough the show is no longer in production, you can enjoy episodes from the TWiT Archives.	https://elroy.twit.tv/sites/default/files/styles/twit_album_art_2048x2048/public/images/shows/netnight_with_amber_and_leo/album_art/sd/natn1400video.jpg?itok=j4WPv0R9
2370	http://i.iinfo.cz/files/podnikatel/505/01-itunes-videobiz-mobile-xml.xml	Videobiz (Mobile)	Podnikatel.cz	Rozhovory s odborníky a zkušenými matadory, rady a tipy pro začínající podnikatele. To je Videobiz, který přináší Podnikatel.cz. Chcete být hostem? Pište na adresu: videobiz@podnikatel.cz	http://i.iinfo.cz/files/podnikatel/560/logo-videobiz-pro-itunes-1.png
2371	http://thecatfromparis.podOmatic.com/rss2.xml	Da Cat' Podcast : French' Fresh mix	the cat from paris	Bienvenue sur mon pocast Electro/house !!\n\nWelcome on my Electro/house'podcast !!\n\nBienvenido en mi Electro/house podcast !!\n\nVous trouverez dans mes French' Fresh Mix une selection des meilleurs morceaux electro/house du moment mixés et remixés par DA Cat (From Paris): un soigneux mélange de hits et de nouveautés.\n\nChaque mois 60 minutes de bonheur à écouter et partager avec vos amis !!\n\nVous y retrouvez aussi mes prods en téléchargement direct sur votre Itunes.\n\n\n\nEverywhere, everytime, everybody ...\n\nENJOY !!\n\nPour consulter les playlists :\nPlaylists available on :\n\nFacebook: http://www.facebook.com/pages/Paris-France/Da-Cat-from-Paris/255880802266	https://assets.podomatic.net/ts/2f/76/fd/thecatfromparis/3000x3000_3533480.jpg
2373	http://www.blogtalkradio.com/alvina-smith.rss	UB Centered	Archive	The mission of UB Centered Institute is simple; One God, one earth, and we are all living and breathing human beings. UB Centered is about assisting you to a state of peace, equilibrium with spirit, mind and body; aiding you with nutrition, through food education and spiritual support. UB Centered Institute endorses each naturalistic and holistic healing approach depending on the client needs with respect and confidentiality, offering transformational and nutritional coaching. Additional resources used visualization and meditation. UB Centered Institute mission is to bring you closer to complete balanced health and wellness.	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/13e19316eef5ea94319ea334f066a9f7.jpg
2375	http://itunes.muchobeat.com/mb.php	Dj Agustin Sessions - PodCast	Dj Agustin	🔥🇲🇽Top Dj🔥\n🔊OpenFormat/House/Urban/🔊\n🔥Club…	https://i1.sndcdn.com/avatars-aoxNcBKZUFyzU0Tg-MU5wzQ-original.jpg
2376	http://www.theshareddesk.com/?feed=podcast	The Shared Desk	pip@pjballantine.com (Tee Morris)	Two Writers, One Podcast, and Various Points-of-View	http://www.theshareddesk.com/wp-content/uploads/2020/04/shareddesknottransparent-scaled.jpg
2377	http://www.digitfamily.com/math_video/Mathematics_Videos/rss.xml	Visualizing Mathematics	Linda Roper	A picture is worth a thousand words - so they say.\r\rI hope these short videos are helpful to see mathematics from a visual perspective.	http://www.digitfamily.com/math_video/Mathematics_Videos/Mathematics_Videos_files/cover.jpg
2379	http://feeds.feedburner.com/preneurcast	PreneurCast: Entrepreneurship, Business, Internet Marketing and Productivity	PreneurGroup	Author and serial entrepreneur Pete Williams and Digital Media Producer Dom Goucher discuss Entrepreneurship, Business, Internet Marketing and Productivity (with a fair smattering of Software and Gadgets too). Hosted by Pete Williams and Dom Goucher.	http://assets.libsyn.com/images/preneurcast/pw-podcast-logo2.jpg
2380	http://wizard2.sbs.co.kr/w3/podcast/V0000337995.xml	안지환, 김지선의 세상을 만나자	SBS Contents Hub	SBS 러브FM 09:05 ~ 12:00	http://img2.sbs.co.kr/sbs_img/2015/10/07/podcast_1400x1400.jpg
2421	http://feeds.feedburner.com/GRACEcast/BreastAudio	GRACEcast Breast Cancer Audio	cancerGRACE - H. Jack West, MD (west@cancergrace.org)	Oncology experts summarize current and emerging issues in cancer management for patients and caregivers. Information from the Global Resource for Advancing Cancer Education (GRACE) helps people to become informed partners in their care.	http://cancergrace.org/images/GRACEcast_Podcast_Badge_5_Breast_audio_1400x1400.jpg
2422	http://feeds2.feedburner.com/rockitbomb/podcast	RockitBomb Podcast - Interviews and Music	RockitBomb (admin@rockitbomb.com)	Interesting interviews with interesting people.	http://rockitbomb.com/podcast/images/rbpod.jpg
2424	http://faithatfirst.libsyn.com/rss	FaithatFirst Podcast	Candi Boutwell	Worship and music from First United Methodist Church of Evanston, IL	http://static.libsyn.com/p/assets/c/e/c/7/cec74f5a804d1212/soapy.png
2381	http://www-personal.umich.edu/~thyliasm/limitedfork/limitedfork.xml	Limited Fork	Thylias Moss	The Limited Fork show featuring POAMs: Products of Acts of Making in fulfillment of principles of Limited Fork Poetics: the study of interacting language systems, where the visual, sonic,  tactile, and olfactory meet to form and reform (compelling) structures.  Where focus on an intensely stabilizing area can still produce (forms of) sonnets that will maintain a particular form for only a limited period of time after which other structure(s) emerge, some of the emergence occurring across physical, sensory, and other dimensions.\n\nThis podcast is the place where POAMS, products of acts of making, will evolve, for the idea (as well as the poams that come out of the idea) is dynamic, seeking ways to fulfill the need for expression that coincides with unfolding understandings of existence.  At the end of one of the branching roots of LFP and at the tip of one of the branches is belief in the pleasure of making things, a pleasure increased by acts of making that understand and try to take advantage of the range of what is possible and available.\n\nBY FOCUSING ON INTERACTIONS, THE WHOLENESS OF THE ORGANISM IS EMPHASIZED.  \n\nThe LFP experiment will showcase successes and failures, for the dead ends, the branches that do not bear sweet fruit, edible fruit, or any fruit at all, nevertheless contribute meaningfully to the recognizable structure of the tree.  Perhaps the beauty of the tree depends on the presence of some dead ends.\n\nEvery week, there will be a visual or sonic episode (a branch) that reflects the current status of the ongoing study of interacting language systems.   The LFP show will always present what is within its changing limits.  Not (just) poems, but POAMS.\n\nTo hear more music of Limited Fork, visit the Limited Fork Music podcast.  For more Limited Fork movies, visit the Limited Fork Video Anthology to download the video work of student and other practitioners of what Limited Fork Poetics enables and encourages.	http://www-personal.umich.edu/~thyliasm/limitedfork/html/limitedfork/logo12a300.jpg
2382	http://www.buzzsprout.com/7374.rss	Christian Life Austin	Christian Life Austin	A Spirit filled and Spirit led Church in Austin, TX - Lead Pastor Rex D. Johnson.	https://storage.buzzsprout.com/variants/ZnksJC5prd3aAnFHM3rFx6S5/8d66eb17bb7d02ca4856ab443a78f2148cafbb129f58a3c81282007c6fe24ff2?.jpg
2383	http://nineye.podomatic.com/rss2.xml	Nineye's Podcast	Nineye		https://assets.podomatic.net/ts/32/55/87/paulawub-scully/3000x3000_3475014.jpg
2385	http://www.franklinchurchofchrist.net/sermons/date/2008/rss/podcast.rss	Franklin Church of Christ (2008 Podcast)	The Word of God	As evidenced by the example of Paul at Troas in Acts 20:7, proclamation of the Word of God was part of the assemblies of the early churches. In nearly all of our assemblies, a lesson from the Word of God will be presented for us to consider (cf. Acts 17:11). Podcasts of these sermons can be found in the directory below.	http://www.franklinchurchofchrist.com/images/bldg.jpg
2387	http://www.blackhat.com/podcast/bh-japan-06-audio.rss	Black Hat Briefings, Japan 2006 [Audio] Presentations from the security conference	Black Hat	Past speeches and talks from the Black Hat Briefings computer security conferences.\nThe Black Hat Briefings in Japan 2006 was held October 5-6 in Tokyo at the Keio Plaza Hotel. Two days, four different tracks. Mitsugu Okatani, Joint Staff Office, J6, Japan Defense Agency was the keynote speaker. Some speeches are translated in English and Japanese. Unfortunately at this time speeches are not available in Both languages.\n\nA post convention wrap up can be found at http://www.blackhat.com/html/bh-japan-06/bh-jp-06-en-index.html \n \n If you want to get a better idea of the presentation materials go to http://www.blackhat.com/html/bh-media-archives/bh-archives-2006.html#AS_2006 and download them. Put up the .pdfs in one window while listening the talks in the other. Almost as good as being there!\n\nVideo, audio and supporting materials from past conferences will be posted here, starting with the newest and working our way back to the oldest with new content added as available! Past speeches and talks from Black Hat in an iPod friendly .mp3 audio and.mp4 h.264 192k video format.	http://media.blackhat.com/bh-japan-06/bh-japan-06-itunes.jpg
2388	http://www1.swr.de/podcast/xml/swr2/interviews.xml	SWR2 Tagesgespräch	Südwestrundfunk	Im Tagesgespräch widmen wir uns jeden Morgen einem aktuellen Thema des Tages: Wer hat die Entscheidung getroffen? Und warum? Wo waren die Alternativen? Und was sagt die andere Seite dazu? Wir befragen Politiker*innen, Expert*innen, Vereine, Betroffene und Aktivist*innen.	https://www.swr.de/swr2/programm/1567610838613,swr2-tagesgespraech-podcast-106~_v-1x1@2dXL_-1f32c27c4978132dd0854e53b5ed30e10facc189.jpg
2389	http://www.trigames.net/rss.xml	Trigames.NET Podcast	MrCHUPON (mrchupon@trigames.net)	Dive into the nonsensical rantings of the Trigames.NET staff as they discuss games, the game industry, game journalism, and alcohol.	http://trigames.net/pics/tricast.gif
2391	http://www.joqr.co.jp/takeda_pod/index.xml	武田鉄矢・今朝の三枚おろし	文化放送PodcastQR	温かさと厳しさを併せ持つ武田鉄矢が毎週テーマに添ってさまざまな語りを展開。\nどんな話題でも美味しくさばいて見せマス！	https://www.omnycontent.com/d/playlist/92f07af0-df9c-498e-a68a-ab4201477bd9/7d90b43f-19f0-473c-b63a-ab4300804499/2691c377-e951-49ce-8a24-ab4300804499/image.jpg?t=1594172634&size=Large
2393	http://arevoltadovinyl.podOmatic.com/rss2.xml	A REVOLTA do Vinyl | Ricardo Guerra	A REVOLTA do Vinyl | Ricardo Guerra	::. A REVOLTA do Vinyl .::\n1 hora de música cheia de energia para respirar e também para dançar com Ricardo Guerra.\nSábados, 23h - Meia-Noite, na Oxigénio 102 6 fm, Lisboa.\n1 music hour full of energy to breathe and also to dance, with Ricardo Guerra in the mix.\nSaturdays, 23h - 00h, on Oxigénio Radio 102 6 fm, Lisbon.	https://assets.podomatic.net/ts/35/20/aa/arevoltadovinyl/3000x3000_11696551.jpg
2394	http://feeds.feedburner.com/radioactivity	Radio Activity	WMNF 88.5 FM Tampa	WMNF's Rob Lorei confers with guests and listeners about issues in the local and global community.	http://www.wmnf.org/wp-content/themes/bsd-theme/wmnf/assets/wmnf_podcast_icon.jpg
2395	http://feeds.feedburner.com/techarts	T+A: Technology and the Arts	Brian Kelley and John LeMasney	Technology and the Arts seeks to explore the connections between technology and art, and to establish a forum for discussing the impact technology has made on the human creative process and on literature, music, and the visual and interactive arts.	http://techarts.files.wordpress.com/2007/04/techarts_itunes_logo.jpg
2396	http://webtalkradio.net/internet-talk-radio/category/podcasts/science-and-medicine/are-ufos-real/feed/	Are UFOs Real? - T.L. Keller	webtalkradio@comcast.net (T.L. Keller )	Are UFOs Real?  Over the last 60 years we have heard reports of unidentified flying objects . . . UFOs.   We have heard from skeptics that they are all either imaginary, hallucinations, hoaxes or strange, but natural aerial phenomenon.   On the opposite side of the fence, believers say that of all observed UFOs some 5% or so are real, solid objects.  What is the reality of this?  In this series, we will hear from both believers and skeptics alike to help our listeners determine: Are UFOs Real?  And if they are real, what will be the impact on Earth, our technology, our environment and our society?	https://webtalkradio.net/all-images/iTunesImage/ThomasKelleriTunes.jpg
2397	http://calientenocheradio.podOmatic.com/rss2.xml	Caliente Noche Radio !	Hugo  Cantarra		https://assets.podomatic.net/ts/ab/19/86/calientenocheradio/3000x3000_2341975.jpg
2512	http://www.lexisnexis.com/mealeys/podcasts/legalnews_podcast_environmental.xml	LexisNexis® Environmental Law & Climate Change Community Podcast	LexisNexis®	LexisNexis® Mealey's™ now makes New Environmental Law & Climate Change interviews available via Podcast.	http://www.lexisnexis.com/mealeys/podcasts/LexisTSlogo.jpg
2398	http://www.islamhouse.com/pc/401375	قراءة كتاب صحيح البخاري	IslamHouse	صحيح البخاري كتاب نفيس روى فيه الأحاديث الصحيحة الثابتة عن رسول الله - صلى الله عليه وسلم - وسماه « الصحيح المسند من حديث رسول الله صلى الله عليه وسلم وسننه وأيامه ».<br />\n• قال ابن كثير في البداية والنهاية: « وأجمع العلماء على قبوله - يعنى صحيح البخاري - وصحة ما فيه، وكذلك سائر أهل الإسلام ».<br />\n• وقال النووي في مقدمة شرحه لصحيح مسلم: « اتفق العلماء - رحمهم الله - على أن أصح الكتب بعد الكتاب العزيز الصحيحان البخاري ومسلم وتلقتهما الأمة بالقبول، وكتاب البخاري أصحهما وأكثرهما فوائد ومعارف ظاهرة وغامضة، وقد صح أن مسلما كان ممن يستفيد من البخاري ويعترف بأنه ليس له نظير في علم الحديث ».<br />	http://islamhouse.com/islamhouse-sq.jpg
2400	http://feeds.feedburner.com/imp	Glimpster Video Podcasts	Israel Hyman (feedback@idlemindspodcast.com)	We're addicted to the media. We love television, movies, books, and music . . . Come indulge in your addiction with us!	http://idlemindspodcast.libsyn.com/podcasts/idlemindspodcast/images/300newlogo05.jpg
2402	http://zbj.podomatic.com/rss2.xml	The ZB&J Podcast!	David McCutcheon	Join ZoopSoul, brisulph, and roundthewheel as they discuss the goings-on in the gaming industry, Iron Sheik's tweets of the week, and even some obscure Nintendo Power features from the 1980s and '90s!	https://assets.podomatic.net/ts/93/10/bc/davidjmccutcheon/1400x1400_8174285.png
2404	http://gamesoggadgets.podomatic.com/rss2.xml	Games og Gadgets	Magnus Pedersen	En podcast om spil og gadgets.	https://assets.podomatic.net/ts/34/41/b6/magnusmpedersen/3000x3000_5565061.png
2405	http://feeds.feedburner.com/NzVeganoPodcast	NZ Vegano Podcast	Elizabeth Collins	Continuando el mensaje del veganismo abolicionista en Nueva Zelandia.	https://1.bp.blogspot.com/_lz5v5k_29yA/SY5GlSCHL_I/AAAAAAAAAAg/tIAbGSaOdAg/S1600-R/NZVeganoPic.jpg
2406	http://feeds.feedburner.com/Boktimmen	Boktimmen	Radio AF 99,1 (boktimmen@radioaf.se)	Diskuterar och recenserar böcker, både samtidsaktuella och klassiker.	http://dl.dropbox.com/u/89285236/BoktimmenRadioAF/profilbild.jpg
2409	http://the12thmanpodcast.podomatic.com/rss2.xml	The 12th Man Podcast	The 12th Man	The 12th Man Podcast is a weekly football podcast release every friday focusing on Premiership and european football alongside all the talking points from the weeks football... We appreciate all feedback so email us at the12thmanpodcast@hotmail.com or join us on facebook http://www.facebook.com/pages/Dublin-Ireland/The-12th-Man-Podcast/126489397397467?ref=sgm	https://assets.podomatic.net/ts/9c/cf/22/the12thmanpodcast/3000x3000_3152521.jpg
2410	http://www.gracecathedral.org/mp3/podcast/forum-podcast.xml	The Forum at Grace Cathedral	Grace Cathedral	Education, public discussion and civic conversation are all central to the life of Grace Cathedral and its engagement with the city of San Francisco, the Bay Area, the Diocese of California and the wider church.\n\nThe Forum promotes the open discussion of ideas about faith and ethics in relation to the issues of our day. It hosts interviews with leading public figures and panel discussions with politicians, musicians, writers, scientists, theologians and many others. And it collaborates with the leading cultural institutions and universities of the Bay Area to bring the most innovative and interesting thinking to our public space.	https://e573e28f91dbded8a779-60508ec5c7cc1b1e276bff073633093c.ssl.cf1.rackcdn.com/image/Podcasts/Podcast-Forums.jpg
2411	http://www.abc.net.au/radionational/feed/3774754/podcast.xml	Separate stories podcast	ABC Radio	Books and Arts explores the many worlds of performance, writing, music and visual arts, and features interviews with local and international authors and artists.	http://www.abc.net.au/cm/rimage/6091706-1x1-large.jpg?v=11
2412	http://madscientistpartyhour.libsyn.com/rss	Mad Scientist Party Hour	RiotCast.com	Hear the twisted tales from the travels of mad scientists Kevin Kraft, Shuddy Boy and Geoff Clark, a bizarre team of slackers with dreams of world domination. You'll get a weekly dose of lunacy and a unique perspective on what's happening in the world around you... along with the occasional live experiment with themselves as the test subjects. www.RiotCast.com	https://ssl-static.libsyn.com/p/assets/1/9/b/6/19b67439ea4b2745/madscienitst_1400_2014.jpg
2413	http://www.blogtalkradio.com/wspa.rss	Art of the Spa's Spa Brunch	Archive	Can't get to the spa?  Candy, lifestyle expert & author, brings it to you!  Dubbed the "Martha" of the robe & slipper set, she'll whisk you to the best spas & help you bring the luxe home with health, decor, beauty, food & entertaining advice, music & more.	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/879daca858a1181d38966f4b319763ee.jpg
2414	http://korepe.edublogs.org/feed/	PE	\N	Another excellent Edublogs.org weblog	https://edublogs.org/files/2020/05/edublogsfav.png
2415	http://feeds.feedburner.com/animoadelante	Iglesia Tiempo de Dios (Audio)	Francisco López	Somos una iglesia protestante en la Ciudad de Dallas. Estamos en el camino que conduce a la Ciudad de Dios. Aquí encontrarás los sermones en AUDIO del Pastor Francisco López. Envía comentarios: info@tiempodedios.com	http://www.animoadelante.com/AA_podcast_icon.jpg
2416	http://gaysowhat.podbean.com/feed/	Gay So What - 明日もゲイ	Gay So What	40代おじさんゲイ仲間が飲みながらアホな事をだらだら喋るポッドキャスト「明日もゲイ」を配信してます。\n\nご質問・コメント等お待ちしております！\n\nMAIL: ashitamogei@gmail.com\nTWITTER: @ashitamogei	https://pbcdn1.podbean.com/imglogo/image-logo/416603/podcast_badge_1905.jpg
2417	http://feeds.feedburner.com/TSF-Eureka	TSF - Eureka - Podcast	TSF (tsf@tsf.pt (TSF Radio Notciais))	O programa revela as investigações dos cientistas nacionais e as criações tecnológicas que distinguem os portugueses. Os avanços da ciência e tecnologia "made in Portugal", numa parceria entre a TSF e o Centro de Multimédia da Universidade de Aveiro.	http://www.tsf.pt/favicon.ico
2419	http://feeds.soundcloud.com/users/25261528-leshowharryshearer/tracks	Harry Shearer: Le Show	Harry Shearer	A weekly, hour-long romp through the worlds of me…	http://i1.sndcdn.com/avatars-000712608439-49n0yp-original.jpg
2420	http://feeds.feedburner.com/MikeTechniques	The Workflowing Podcast	Michael Schechter and Mike Vardy	Casual conversations on productivity and self-improvement with Michael Schechter and Mike Vardy of Workflowing. Guest interviews and candid conversations on how you can do better.	http://www.buzzsprout.com/podcasts/8150/artworks_large.jpg?1368541188
2543	http://smodcast.com/channels/jay-silent-bob-get-old/feed/	Jay & Silent Bob Get Old	SModcast Network (info@smodcast.com)	No Trench Coats. No Hair Extensions. Bound for the Grave. This is what happens when Jay & Silent Bob Get Old.	http://i1.sndcdn.com/avatars-000309983285-92en5d-original.jpg
2426	http://feeds.asiasociety.org/asiasociety/eqec	Asia In-Depth	Asia Society	There's never been a better time to understand what's going on in Asia. That's why we talk to the people who know it best. The Asia In-Depth podcast brings you conversations with the world's leading experts and thought-leaders on the politics, economics, and culture of Asia — and beyond. Subscribe today.	http://www.asiasociety.org/podcasts/asiaindepthpic2.jpg
2427	http://rss.dw-world.de/xml/podcast_forum-des-cultures	Forum des cultures | Deutsche Welle	DW.COM | Deutsche Welle	Cinéma, littérature, musique : la rencontre de la semaine!	https://static.dw.com/image/2144203_7.jpg
2433	http://promodj.com/graver/podcast.xml	Graver	PromoDJ (graverdj@gmail.com)	VKONTAKTE: vk.com/djgraver \n FACEBOOK: www.facebook.com/graverof... \n YOUTUBE: www.youtube.com/djgraver	https://cdn.promodj.com/afs/15f3a63e33fbe8bf1f45b49465c17fbc12:resize:1400x1400:same:730e63.png
2434	http://librivox.org/rss/4608	Coffee Break Collection 005 - Love and Relationships by VARIOUS	LibriVox	This is a collection of 20 short works (between 3 and 15 minutes long) that are great for work/study breaks, commutes, workouts, or any time you'd like to hear a whole story and only have a few minutes to devote to listening. The theme for Collection 005 is "Love and Relationships", and may include romance, marriage, family relationships, friendships, working relationships, or even human-animal connections! [Summary by Rosie]	\N
2435	http://www.metrofarm.com/assets/feeds/feed.xml	The Food Chain - What's Eating What Radio	\N	The Food Chain is an audience-interactive newstalk radio program that airs live on Saturdays from 9am to 10am Pacific time. The Food Chain, which has been named the Ag/News Show of the Year by California's legislature, is hosted by Michael Olson, author of the Ben Franklin Book of the Year award-winning MetroFarm, a 576-page guide to metropolitan agriculture.	\N
2440	http://feeds.feedburner.com/ComicPopLibraryPodcasts	Podcasts – comicpop library	comicpoplibrary.com	Four librarians have fun reviewing and discussing the comic books, graphic novels, manga, anime/animation and movies that hey have recently read or seen.  Great for librarians seeking reviews for what they are considering purchasing and anyone with a general interest in these formats.	http://comicpoplibrary.com/wp-content/uploads/2010/12/cpllogo300.jpg
2443	http://feeds.feedburner.com/InsideLineRoadTestVideos	Inside Line Road Test Videos	Edmunds' Inside Line	Edmunds' Inside Line is an online automotive enthusiast magazine that delivers exclusive road tests, spy videos, news, auto show coverage, blogs, and more to you every day.  Check out www.insideline.com for daily updates.	http://a.images.blip.tv/InsideLineRoadTests-300x300_show_image687.JPG
2444	http://nelsonribeiro.podomatic.com/rss2.xml	Nelson Ribeiro's Elation Podcast	Nelson Ribeiro	Nelson Ribeiro brings you his selection of the finest in progressive, uplifting, melodic, & tech trance every month.	https://assets.podomatic.net/ts/7a/96/3e/nelsonribeiro/3000x3000_5098680.jpg
2447	http://beyondthe140.podomatic.com/rss2.xml	Beyond The 140	Beyond The 140	Beyond The 140 gets behind the TLs of some of your favorite tweeters. Join the fun each Tuesday @ 11P ET with @JCWisdomNuggets and @iAmDelFreaky.\n\nSubscribe to our NEW feed here: https://itunes.apple.com/us/podcast/beyond-the-140/id881444374?mt=2	https://assets.podomatic.net/ts/c1/6d/90/joeycwisdomnuggets46772/3000x3000_9217681.jpg
2448	http://recordings.talkshoe.com/rss16981.xml	Breaking Bad Edition	bogaman	An unofficial fanmade podcast dedicated to the AMC TV show Breaking Bad. Hosted by Bill, Trent, and Nate Bjork. We do not take ourselves too seriously and sometimes get off topic but in a funny way and games, yes, games. Visit us behindthecuttingedge.com  Be sure and call our voicemail line @ 209-LOL-BTCE with your thoughts about Breaking Bad after the show, or email us behindthecuttingedge@gmail.com	https://show-profile-images.s3.amazonaws.com/production/840/breaking-bad-edition_1531860451_itunes.png
2451	http://nachtgedanken.podspot.de/rss	Nachtgedanken	Ti	Geschichte einer Krankheit in Zeiten neoliberaler Gesundheitsreformen	\N
2452	http://recordings.talkshoe.com/rss88168.xml	PODTOURAGE	podtourage4	Podtourage is a podcast devoted to the great events of life. Each week your hosts will talk about 4 topics ranging from Movies, Sports, Televsion, Relationships and Current events.    A fun podcast with 4 friends from California, Louisiana, Massachusettes and North Carolina.    Heath Solo (Lost Revisited Now and The Film List), Donald Chavis (Donald is Lost, Fringe Podcast and Re-Opening the X-Files), Alex Hahn (It Only Ends Once, Missing White Girl) and Axel Foley (Lost Mythos Theory Cast) are your hosts.	https://show-profile-images.s3.amazonaws.com/production/1766/podtourage_1531861372_itunes.png
2454	http://blindspotmusic.co.uk/rss/podcast.php	Norbert Hoffmann presents Blind Spot	Blind Spot	Norbert Hoffmann (previously known Dr. Hoffmann) presents Blind Spot. Norbert brings you the best in Techno music from around. No hype, No compromise, only The Sounds of The Underground.	http://blindspotmusic.co.uk/rss/blindspot_rss.jpg
2455	http://www1.swr.de/podcast/xml/swr2/zeitwort.xml	SWR2 Zeitwort	Südwestrundfunk	Das Zeitwort erinnert an historische Daten aus allen Bereichen von Kultur und Gesellschaft.	https://www.swr.de/swr2/programm/1564748409885,swr2-zeitwort-100~_v-1x1@2dXL_-1f32c27c4978132dd0854e53b5ed30e10facc189.jpg
2456	http://www.elinvernaderoradio.com/Podcast/invernadero.xml	El Invernadero Radio	Lucinda V.	El Invernadero Radio a traves de 94.9FM (Monterrey), domingos al mediodia y con transmision a traves de internet cualquier dia en www.elinvernaderoradio.com, podcast aqui! . Musica para los oidos no polarizados, para lo nuevo, lo diferente, jazz, indie, spage age pop y mas.	http://www.elinvernaderoradio.com/images/logo.jpg
2459	http://www.1101.com/itunes/podcast.xml	ほぼ日刊イトイ新聞 Podcast	ほぼ日刊イトイ新聞	ほぼ日刊イトイ新聞のポッドキャスト。	http://www.1101.com/itunes/podcast.jpg
2461	http://www.florenceporcel.com/podcast/lfhdu.xml	La folle histoire de l'Univers	Florence Porcel	Podcast d'une passionnée des sciences de l'Univers	http://www.florenceporcel.com/podcast/logo.jpeg
2462	http://www.cc-ob.tv/feed_sermons.php	Christ Church	Various	Sermons from Christ Church of Oak Brook, Oak Brook, Illinois. We are a vital non-denominational church where children, youth, and adults alike build life-changing relationships with God and one another. Each week, we offer you a variety of inspiring worship services, a rich range of spiritual growth resources, and a selection of service ministries aimed at changing the world for good.	http://media.cc-ob.org/images/ccobPodcast.jpg
2513	http://mydiningroomtable.libsyn.com/rss	My Dining Room Table with Adam Cayton-Holland	Adam Cayton-Holland	Comedian Adam Cayton-Holland chats with the various interesting people that cross his path about the various routes to success and the various interpretations of what "making it" means. All from his dining room table. Various.	https://ssl-static.libsyn.com/p/assets/4/2/5/d/425df1a8b8f107b5/MDRT_Logo_square.jpg
2463	http://www.imightbeacroc.com/alligator.xml	The Alligator - I Might Be A Croc, I Don't Know - Show	Robert Hamilton	Comedy podcast. MP3 format. Occasionally -- if we feel like it. This podcast features our friend, Alligator, in skits from an imaginary swamp. Alligator spouts thought-provoking nonsense, and eats almost anything he can get his jaws around.\nHe's no dummy, though: In the midst of his babble you'll likely hear references to science, math, technology, and arcane vocabulary, as well as thinly veiled commentary on contemporary topics.\nAlligator is always coming up with new theories and inventions, which may amuse and will definitely confound you. Sometimes surreal, often thoughtful, and full of improvisation. Stream of consciousness. Look for our Podcast in the iTunes\nStore.	http://imightbeacroc.com/RoundGatorLogo18-clenup1-small-transparent.gif
2466	http://jessicastickler.hipcast.com/rss/jivamuktiwithjessica.xml	Jivamukti Yoga with Jessica Stickler	Jessica Stickler	Jivamukti Yoga classes live from the mother ship in New York City's Union Square. Jessica teaches musically infused and philosophically amused classes that aim to inspire, uplift, incite, and ignite! Jivamukti classes combine physical technique with music, spiritual scripture, non-violence, and meditation. \nIf you enjoy the podcast, please visit: http://yogastickler.com/donate-now	https://jessicastickler.hipcast.com/albumart/1000_itunes_1602693027.jpg
2467	http://feeds.feedburner.com/TontoElKeLoLeaPodcast	TONTO EL KE LO LEA PODCAST	@tontoelkeloleapodcast	Podcast de tematica tecnologica distendida de apple y android, noticias tecnologicas, y endogamia spreakeriana podcastera	https://lh3.googleusercontent.com/-724WvPXsvwE/AAAAAAAAAAI/AAAAAAAAADQ/c3vppmPh3u8/s250-c-k/photo.jpg
2468	http://www.rte.ie/radio1/podcast/podcast_dramaonone.xml	Drama On One	RTÉ	RTÉ Radio Drama's audio theatre department has for decades proudly brought audiences the very best dramatic writing and performances for radio from Ireland. Listen every Sunday night at 8pm at RTÉ Radio 1, visit rte.ie/dramaonone for more.	https://img.rasset.ie/0014a187-144.jpg
2469	http://feeds.feedburner.com/Vortex4	Philosophy of Time Travel	Roberta  Sparrow	<center>This intent of this short book is to be used as a simple and direct guide in a time of great danger....</center>\n<br />\n\n\n<center><p><a href="http://www.CyberpunkPinups.com">-- Roberta  Sparrow ::  Paris, France, 2038 RA --</a></p></center>\n<br />	http://homepage.mac.com/vortexfour/metroshield.jpg
2470	http://feeds.feedburner.com/wyep/prosody	91.3fm WYEP: Prosody	91.3fm wyep	Prosody is WYEP's weekly show featuring the work of poets and writers. Each week, hosts Jan Beatty and Ellen Wadey sit down with writers as they read and discuss their fiction, poetry and non-fiction. Prosody has been a weekly show on WYEP since the early 90's.	http://www.wyep.org/images/podcasts/prosody75.jpg
2472	http://feeds.feedburner.com/mgctv	MGCTv. PODCASTING. EVOLVED.	The Voices of MGCTv	An assortment of London based voices bringing you funny conversations of whatever is topical in the world of entertainment. Occasionally joined by our allies in the USA. Debate is always encouraged!!	http://dl.dropbox.com/u/16516663/MGCTv_New_Logo3.png
2474	http://www.angelfire.com/ky/slipstream/rfprss.xml	Radio Free Philosophy	Kevin Browne, Robert Urekew	Philosophy discussions to enhance your understanding of the classes you are taking with us.	http://www.angelfire.com/ky/slipstream/radio.jpg
2475	http://feeds.feedburner.com/spacehommeradio	SPACE HOMME RADIO	Julioso	SPACE HOMME RADIO is the official podcast of Julioso. Picking up where his debut EP left off, this podcast features unreleased tracks, collaborative works, remixes, and much more, providing an exciting sonic journey through the world of Julioso.	http://img715.imageshack.us/img715/9343/shrcover.jpg
2478	http://www.porsche.com/all/standalone/podcast/german/porschepodcast.xml	Sound of Porsche - Stories of the Brand	porschepodcast@bb-k.com (Bassier, Bergmann & Kindler)	Envelop yourself in the world of Porsche through these newly-procuced video Podcast series. Fascinating stories will deliver previously unseen insights into the brand.	http://www.porsche.com/all/standalone/podcast/german/podcast_icon_pag2.png
2480	http://feeds.feedburner.com/mearablogpodcast	The Mearablog Podcast	Paul Meara	Introducing the Mearablog Podcast on iTunes. The MB Podcast takes listeners into the lives of college and professional athletes, politicians, musicians or pretty much anything you can think of. This is not just another boring podcast with some schmo blabbing on about nothing. This is the real deal with exclusive interviews of some of your favorite personalities. Visit the iTunes Music Store and search: The Mearablog Podcast. Subscribe today for FREE to see what's cooking on the Mearablog.	http://i605.photobucket.com/albums/tt134/mearablog/Mearablog-Podcast-Logo-NEW-For-HP.jpg
2481	http://feeds.feedburner.com/CarCast	CarCast	PodcastOne / Carolla Digital	A twice weekly automotive podcast hosted by Adam Carolla, Bill Goldberg and Matt "The Motorator" D'Andria. It's the only show of its kind that explores all aspects of the automotive space from the performance aftermarket, to new car buying and the future of the automotive industry. The guys answer your questions, offer advice and feature guests from the automotive industry and celebrity car enthusiasts.	https://img.podcastone.com/images/320/Carcast3000x3000.jpg
2482	http://podcast.srib.no:8080/Podcast/PodcastServlet?rss24	Bulldozer	Studentradioen i Bergen (ar@srib.no)	Ruller over ukens mediebilde!	http://srib.no/logo/bulldozerpc.png
2485	http://forgotten80s.podomatic.com/rss2.xml	forgotten80s	forgotten80s	Featuring forgotten and overlooked new wave/powerpop music of the early to mid 80's.	https://assets.podomatic.net/ts/ce/0d/c1/forgotten80s/3000x3000_605190.jpg
2486	http://www.dochandal.com/podcast_listenup.xml	Listen Up! | Doc Handal's	\N	Medical Common Sense	\N
2510	http://feeds.feedburner.com/AceOnTheHouse	Ace On The House	PodcastOne / Carolla Digital	Before becoming a comedian, Adam Carolla was a hammer-swinging, ditch-digging carpenter. Now, Adam's bringing that knowledge to you in Ace On The House, a weekly home improvement podcast. Joined by Eric Stromer, the guys take your calls and answer your e-mail questions with an informative, hilarious twist. From contractors to novices, this show is sure to keep you coming back every Saturday to get your weekend dose of Adam.	https://img.podcastone.com/images/319/aceonthehouse_logo_new.jpg
2487	http://ttb.twr.org/rss/vietnamese_main.xml	Tìm Hiểu Thánh Kinh @ ttb.twr.org/vietnamese	The A Group	Bài giảng … là một phần của chương trình “Tìm Hiểu Thánh Kinh”. Đây là chương trình giảng dạy Kinh thánh toàn cầu được sáng lập bởi Tiến sĩ  J. Vernon McGee. Nay chương trình đã được chuyển ngữ sang hơn 100 thứ ngôn ngữ và thổ ngữ khác nhau. Chương trình gồm nhiều bài giảng, mỗi bài dành cho một ngày, kéo dài 30 phút và sẽ hướng dẫn thính giả đi xuyên suốt Kinh thánh một cách có hệ thống. Các bài giảng nầy đã được đưa lên mạng. Chúng tôi tạ ơn Chúa vì bạn bắt đầu học hỏi thêm về Lời Chúa bằng cách lắng nghe các bài giảng nầy. Mời các bạn nghe ít nhất là một bài trong ngày – từ thứ Hai đến thứ Sáu. Nếu bạn liên tục thực hiện như vậy, bạn sẽ học toàn bộ Kinh thánh trong vòng 5 năm.	https://ttb.twr.org/images/r/VIE-itunes/c1400x1400/VIE-itunes.jpg
2489	http://www.tbsradio.jp/tokyopod/index.xml	TBSラジオ 東京ポッド許可局	TBS RADIO 954kHz	TBSラジオで毎週土曜27時（暦日日曜午前3時）～放送！2008年、売れてない芸人3人でひっそり始めた自主制作のポッドキャスト番組をTBSラジオが異例の輸入！モットーは「屁理屈をエンタテインメントに！」エンタテインメントとインタレスト、2つの意味の「おもしろい」を両立させた刺激的な内容を、3人のおじさんが屁理屈たっぷりに語る。金曜28時だったかわいらしい放送時間が、2015年度からは土曜27時というちょっとかわいらしい放送時間に移動。前代未聞のラジオ革命を起こすべく、営業しています。	https://www.tbsradio.jp/tokyopod/300_300.jpg
2490	http://feeds2.feedburner.com/TomorrowsWorld-AudioTelecastLibrary	Tomorrow's World - Audio Telecast Library	Tomorrow's World	The Tomorrow's World magazine is a FREE, full color, bi-monthly magazine full of timely articles and unique insights on issues affecting your life.  This magazine keeps you up to date with current trends, Bible Prophecy, and the exciting news of your future in Tomorrow's World.	http://www.tomorrowsworld.org/images/tw_podcastlogo_large.jpg
2494	http://www.kcm.org/feed/en/itunes/events/2011/audio	2011 Kenneth Copeland Ministries' Events Audio Podcast	Kenneth Copeland Ministries	Enjoy the 2011 Kenneth Copeland Ministries events available through audio podcast. Watch life-changing messages from Kenneth and Gloria Copeland, George and Terri Pearsons, Kelly Copeland, John and Marty Copeland, Jeremy and Sarah Pearsons, Creflo Dollar, Jesse Duplantis, and Jerry Savelle. One word from God can change your life forever!	https://www.kcm.org/sites/all/modules/kcm_feeds/img/itunes_2011events_audio.png?r=1603692360.6957
2495	http://promodj.com/albertogaudi/podcast.xml	DJ ALBERTO GAUDI / MOSCOW CLUB BANGAZ RECORDS	PromoDJ (ejik_atmo@mail.ru)	Alberto Gaudi - российский хаус продюсер, артист, автор ремиксов и бутлегов известных мировых и отечественных композиций. За продолжительную карьеру ( более 20 лет ) выступал на многих площадках России.\nСегодня его выступления взрывают лучшие клубы. Его сеты наполнены невероятной энергетикой. Правильная подача - это залог успеха.\nВ настоящее время Alberto Gaudi является действующим резидентом известного московского клуба The StandarD Bar, ресторана Voshod. Ведет активную гастрольную и...	https://cdn.promodj.com/afs/b895776f784c0a6db17527d0f95f9bb912:resize:1400x1400:same:48b956.png
2496	http://www.spreaker.com/user/5453339/episodes/feed	Noticias 24/7 Puerto Rico	Noticias 24/7 Puerto Rico	Noticias locales e Internacionales, aqui en NOTICIAS 24/7 PUERTO RICO.\nTiempo, Noticias, Deportes, Política, Tecnología, Ambiente...	http://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/109674bef75e8f165391dc4e53ad78f9.jpg
2499	http://feeds.feedburner.com/UnPodcastDeCoches	Un Podcast de Coches	@_Jorge_, @Saighel, @Rober_RnR y @Gl0ri (unpodcastdecoches@gmail.com)	Un Podcast sobre los coches que conducimos o nos gustaría conducir. Grabado por: Jorge (@_Jorge_), Isabel (@Saighel), Rober (@Rober_RnR) y Glori (@Gl0ri). Contacto: unpodcastdecoches@gmail.com	http://dl.dropbox.com/u/1607870/UPDC_LOGO.jpeg
2501	http://feeds2.feedburner.com/Voice-OverJourney	Voice-Over Journey podcast	Wayne Henderson (Wayne@MediaVoiceOvers.com)	The Voice-Over Journey show is the podcast with actionable items, tips, and motivation from voice actors and voice actresses at all different spots in their own voiceover journeys.  Show notes at http://MediaVoiceOvers.com/VOJ	https://mediavoiceovers.com/wp-content/plugins/powerpress/rss_default.jpg
2502	http://feeds.feedburner.com/luee	Life, the Universe & Everything Else	Gem Newman & Ashlyn Noble (lueepodcast@winnipegskeptics.com)	Life, the Universe & Everything Else explores the intersection of science and society.	https://winnipegskeptics.files.wordpress.com/2016/11/luee.png
2504	http://trinitysfl.podOmatic.com/rss2.xml	Trinity High School Revision Notes	Paul Sludden	These podcast episodes are provided by the Support for Learning Department at Trinity High School, Renfrew.\n\nTrinity High School is a Roman Catholic high school in the town of Renfrew, Scotland. Its enrollment is approximately 1075 students. \n\nThe Support for Learning Department consult with class teachers about pupils' additional support needs, and help provide information and advice about your child's learning.	https://assets.podomatic.net/ts/eb/8c/ca/trinitysfl/1400x1400_1735098.jpg
2505	http://feeds.feedburner.com/PaleMicaThePodcast	PALEMICA THE PODCAST	Migz (noreply@blogger.com)	Because four heads are better than one.	http://sphotos-a.ak.fbcdn.net/hphotos-ak-ash4/392832_4440211533042_266640994_n.jpg
2506	http://www.blogtalkradio.com/ministerfortson.rss	The Breakdown	Archive	The Breakdown (formerly The Omega Hour) is hosted by Minister Dante Fortson. Please subscribe to my website for show dates and times. The topics we cover and the questions asked will be determined by the audience. To vote on past and upcoming shows, please visit <a href="http://www.ministerfortson.com" rel="noopener">http://www.ministerfortson.com</a>	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/c4017d2b6c4edb350f1bae06f2423d39.jpg
2507	http://www.eeo.com.cn/podcast/banshangliu_podcast.xml	半上流社会那些事	经济观察网	《半上流社会那些事儿》广播版上线啦！每周二下午15：00戴上耳机快来听！	http://www.eeo.com.cn/podcast/banshangliu_fengmian2.jpg
2509	http://feeds.feedburner.com/povertyunlocked	Poverty Unlocked	Wendy McMahan (povertyunlocked@fh.org)	Poverty Unlocked explores God's heart for the poor and His mandate for Christians. Subscribe to this free series for an in-depth look at Christian relief and development.	http://povertyunlocked.files.wordpress.com/2014/04/pu-itunes-image-1400x1400.jpg
2515	http://www.br-online.de/podcast/gesundheitsgespraech/cast.xml	Gesundheitsgespräch	Bayerischer Rundfunk	Sprechende Medizin – jeden Mittwoch mit einem neuen Thema. Ein offenes Ohr und viel Information für Ihre Gesundheit: von A wie Abnehmen über K wie Krebs bis Z wie Zahnschmerzen. Dr. Marianne Koch und andere Spitzenmediziner stehen Rede und Antwort. Denn: Wissen ist die beste Medizin.	https://img.br.de/1b5cac3f-64e9-4a51-9d8a-9dcd598a136e.jpeg?fm=jpg
2519	http://podcast.wdr.de/radio/wdr2_einfach_gote.xml	Seite nicht gefunden	Westdeutscher Rundfunk	Seite nicht gefunden	\N
2520	http://www.blogtalkradio.com/tuneintomorrow.rss	Tune In Tomorrow	Tune In Tomorrow	Join our lively debates on all things soaps!	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzL2FkMjU1NTk5LTAyNzMtNGZjNi05NmM1LTRhMWQxZWQyNDVkMF90aW50bXlzcGFjZS5qcGc/ad255599-0273-4fc6-96c5-4a1d1ed245d0_tintmyspace.jpg?mode=Basic
2521	http://www.islamhouse.com/pc/344792	L’indulgente religion et sa facilité	IslamHouse	Ce sermon expose les preuves du coran et de la sunna concernant l’indulgence de la religion islamique et sa facilité. Cette religion est facile dans son crédo et sa pratique. Par ailleurs ceci ne veut pas dire qu’il est permis de tomber dans les péchés et les interdits comme dans l’exagération. La pratique religieuse doit être équilibrée sans laxisme ni exagération et outre mesure. Qu’Allah nous facilite cette pratique et le chemin vers le paradis !	http://islamhouse.com/islamhouse-sq.jpg
2522	http://librivox.org/rss/4226	Voyage Towards the South Pole and Round the World, A by COOK, James	LibriVox	Having, on his first voyage, discovered Australia, Cook still had to contend with those who maintained that the Terra Australians Incognita (the unknown Southern Continent) was a reality. To finally settle the issue, the British Admiralty sent Cook out again into the vast Southern Ocean with two sailing ships totalling only about 800 tons. Listen as Cook, equipped with one of the first chronometers, pushes his small vessel not merely into the Roaring Forties or the Furious Fifties but becomes the first explorer to penetrate the Antarctic Circle, reaching an incredible Latitude 71 degrees South, just failing to discover Antarctica. (Introduction by Shipley)	\N
2523	http://www.sermonaudio.com/rss_search.asp?speakeronly=true&keyword=A%2E+W%2E+Tozer	A. W. Tozer on SermonAudio	A. W. Tozer	The latest podcast feed searching 'A. W. Tozer' on SermonAudio.	https://media.sermonaudio.com/gallery/photos/podcast/tozer.JPG
2524	http://joeecons.podOmatic.com/rss2.xml	Joee Cons In The Mix	Joee Cons	Get In The Mix with Canadian DJ and Producer Joee Cons.  In The Mix Podcast features upfont house, tech house, techno, and more.  For upcoming dates, music, and booking information visit https://joeecons.com	https://assets.podomatic.net/ts/e4/43/b1/joeecons/pro/3000x3000_1561369.jpg
2525	http://www.blogtalkradio.com/denzel-musumba.rss	EAST AFRICA RADIO USA	Archive	East Africa radio USA is the fastest and leading media house in the diaspora broadcasting daily in Swahili and English languages,it targets all persons from Africa continent who are in the diaspora and back home.With hot issues of discussion like politics,social daily life,economic matters,news,sports,music and shouts segment..we are what you deserve.Hosted by Kenyas multi-talented broadcaster Denzel Musumba you dont deserve to miss this.	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/5d9b109742ec4ff3b27268c4a9f01519.jpg
2526	http://www3.nhk.or.jp/rj/podcast/rss/swahili.xml	Swahili News - NHK WORLD RADIO JAPAN	NHK (Japan Broadcasting Corporation)	This is the latest news in Swahili from NHK WORLD RADIO JAPAN. This service is daily updated. For more information, please go to https://www3.nhk.or.jp/nhkworld/.	https://www3.nhk.or.jp/rj/images/swahili_1500x1500.png
2527	http://www.pladevender.dk/minimal.rss	mixed by rasmus	Rasmus	www.pladevender.dk	http://www.pladevender.dk/synnyfridayincopenhagen.jpg
2528	http://feeds.feedburner.com/AvidDSTutorials	Avid DS Tutorials	Igor Ridanovic (ask@hdhead.com)	Simple to follow Avid DS tutorials from HDhead.com. View the podcasts and download free presets for Avid DS.	http://www.hdhead.com/custom_images/hdhead_itunes.jpg
2530	http://feeds.feedburner.com/UqOpenCourse-gametheory	UQ Open Course-Game Theory	Dr. Rabee Tourky	The podcasts are lectopia of Level 3 undergraduate course Game Theory in University of Queensland by professor Rabee Tourky. We will learn the knowledges of Nash equilibrium, extensive form of game, bargaining and so on. Record and Published by Mr.Yang HE (Already get permission)	http://www.divshare.com/img/13134372-286.jpg
2532	http://feeds.feedburner.com/HumanitiesInstituteOfIrelandPodcast	UCD Humanities Institute Podcast	UCD Humanities Institute	This podcast series features recordings of academic papers from workshops, conferences and seminars in the UCD Humanities Institute. The Institute provides a creative architectural and conceptual space for interdisciplinary research in the humanities and allied disciplines. The series is managed by Real Smart Media.	http://www.ucd.ie/humanities/events/podcasts/image/HI-Podcast-Thumbnail_2015-1500.jpg
2533	http://sawbones.libsyn.com/rss	Sawbones: A Marital Tour of Misguided Medicine	Justin McElroy	Join Dr. Sydnee McElroy and her husband Justin McElroy for a tour of all the dumb, bad, gross, weird and wrong ways we've tried to fix people.	https://image.simplecastcdn.com/images/a5445fde-0e70-4659-8f18-442f9aabbaac/f24cf20c-122b-425f-a782-cc2aecad305c/3000x3000/sawbones-logo-final.png?aid=rss_feed
2537	http://www.blogtalkradio.com/epradio.rss	ePluribus Radio  with Political Nexus	ePluribus Radio	"Don't Hijack My Thread" is an interactive discussion on today's hot political topics with a progressive slant.  Join "rapid fire" hosts Adam Lambert (clammyc)	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzLzM3NjZfZG9udCUyMGhpamFjayUyMG15JTIwdGhyZWFkJTIwcGhvdG8uanBn/3766_dont_hijack_my_thread_photo.jpg?mode=Basic
2539	http://feeds.feedburner.com/libsyn/uWXs	Gambler's Book Club | Gambling Podcast	Gamblers Book Club - Las Vegas, Nevada	The Gamblers Book Club, located in Las Vegas, Nevada is the largest seller of books and related information on gambling, the gaming industry and related subjects in the world today. Gamblers Book Club has been in business in Las Vegas for more than 40 years. The podcasts will talk about gaming, the latest books, the best books and videos on gambling. Gamblers Book Club Podcast will from time to time have interviews with authors and players of note. The host is the past owner of Gamblers Book Shop, Howard Schwartz, who is considered in the industry one of it's foremost experts on gaming and has been part of Gamblers Book Shop/Club for over 30 years as writer and now as owner.	http://static.libsyn.com/p/assets/9/a/c/3/9ac3eec9326601da/GBC_logo.jpg.jpg
2540	http://feeds.feedburner.com/JobsInPodsIntelJobs	Jobs at Intel Jobcasts	intel.com/jobs/podcasts/	Interviews with employees of Intel Corporation. Listen to them talk about their corporate culture, learn about new job openings and what it's like to work there.	http://jobsinpods.com/images/itunes-images/intel_jobcasts.jpg
2545	http://hlmenckenclub.org/2010-conference-audio?format=rss	2010 Conference Audio - The Mencken Club	H.L. Mencken Club		https://images.squarespace-cdn.com/content/50247edfe4b0ba7ec400564e/1361989217405-JWI6NPVLDXEBL0334Q6M/HLMenckenClub.org.jpeg?content-type=image%2Fjpeg
2547	http://marathontalk.libsyn.com/rss	Marathon Talk	Tom Williams	By runners, for runners - Marathon Talk is a weekly podcast dedicated to keeping you on the inside track to successful running. Experienced multi-sport athletes Martin Yelling and Tom Williams discuss interesting and topical issues from the world of marathon running and along with regular guest interviews provide all the inspiration, motivation and knowledge you need to achieve your goals.	https://ssl-static.libsyn.com/p/assets/c/7/8/8/c7885d5c3899ffc2/mt_podcast_artwork.jpg
2550	http://mod7.cgntv.net:8080/podcast/VP002S/VP002S_sermononthemount.xml	이재훈 목사의 산상수훈 [CGNTV]	CGNTV	온누리교회 2013년 특별새벽기도회 '하늘은 땅에서 열린다' 중 산상수훈 설교	http://mod7.cgntv.net:8080/image/VP002S_sermononthemount.jpg
2555	http://thesureshot.podomatic.com/rss2.xml	The Sure Shot Show	Illvibe Collective	The SureShot is hip hop. New, classic, raw and uncut. True to the form in traditional DJ style... two turntables and a mixer. We feature artist interviews, guest DJs and guest hosts. Bang it on your speakers at the crib, in the car, or in your headphones. We always keep the flavor coming.	https://assets.podomatic.net/ts/6d/95/69/thesureshot/3000x3000_3903450.jpg
2557	http://worldsoccerweekly.podomatic.com/rss2.xml	World Soccer Weekly	Jon Ballenger & John C. Skelton	A weekly podcast discussing all things about the beautiful game. The show will cover topics ranging from the English Premier League to the MLS and more.	https://assets.podomatic.net/ts/45/f6/7d/worldsoccerweekly/1400x1400_3261216.jpg
2559	http://nbuehler59533.podomatic.com/rss2.xml	PA Bible Study 2017	Providence Academy Bible Study		https://assets.podomatic.net/ts/e9/5b/cf/nbuehler59533/3000x3000_8736469.jpg
2560	http://podcast13.streamakaci.Com/xml/GAMEONE2.xml	JT E-NEWS  (PODCAST)	Game One	Retrouvez toute l'actualité du jeu vidéo grace aux e-news quotidiennes du JT de GAME ONE.	http://podcast13.streamakaci.com/images/uploaded/ENews Jeux Video.jpg
2561	http://www.nyas.org/Podcasts/Atom.axd	The New York Academy of Sciences	The New York Academy of Sciences	Bringing together extraordinary people to drive i…	https://i1.sndcdn.com/avatars-000292606443-f01n67-original.jpg
2565	http://rss.dw-world.de/xml/podcast_journal-interview	Interview | Video Podcast | Deutsche Welle	DW.COM | Deutsche Welle	Das "Interview" ist ein Video Podcasting Angebot der Deutschen Welle. Hier finden Sie jede Woche Interviews zu aktuellen Themen. Die Gästeliste liest sich wie ein "Wer ist Wer?" Deutschlands und Europas.	https://static.dw.com/image/49814703_7.png
2567	http://audioboo.fm/users/47496/boos.rss	Robert Johnson's posts	Audioboom	Robert Johnson's recent posts to audioboom.com	http://assets.theabcdn.com/assets/ab-wordmark-on-blue-600x600-d99e66d8a834862dec08e4f3cd1550b575254fb4b38902fb07ef5af5f0aeb21f.png
2569	http://www.cbc.ca/podcasting/includes/wordoftheweek.xml	C'est la vie's Word of the Week from CBC Radio	CBC Radio	CBC Radio's C'est la vie's Word of the Week is a window into the life of French-speaking Canadians -- one word at a time. In repeats over the summer.	https://www.cbc.ca/radio/podcasts/images/promo-wordoftheweek.jpg
2571	http://podiobooks.com/rss/feeds/episodes/flatland-a-romance-of-many-dimensions/	Flatland: A Romance of Many Dimensions	A Square (Edwin Abbott Abbott)	Math.  Geometry.  Physics.  Violence?  Is this the same book I read in school?  Yep.\n\nOne of the joys of rediscovering old books is that they still have the ability to surprise, even shock.\n\n"If my poor Flatland friend retained the vigour of mind which he enjoyed when he began to compose these Memoirs, I should not now need to represent him in this preface, in which he desires, fully, to return his thanks to his readers and critics in Spaceland ... But he is not the Square he once was.  Years of imprisonment, and the still heavier burden of general incredulity and mockery, have combined with the thoughts and notions, and much also of the terminology, which he acquired during his short stay in Spaceland. ..."\n\nYou may remember Flatland as a clever children's story about squares and triangles and such living a happy life in a sheet of paper, a story about math and geometry and such.  No, not so much.  \n\nSure, there's no Adult Language or Sex.  But there's plenty of violence.  I recall recording one scene wherein over 120,000 people were stabbed to death, torn to pieces and eaten by their fellow Flatlanders.  Yes.  Way.\n\nAssuming you consider Isoceles Triangles people.  In Flatland, they are.  Mostly.\n\n"Imagine a vast sheet of paper on which straight Lines, Triangles, Squares, Pentagons, Hexagons, and other figures, instead of remaining fixed in their places, move freely about, on or in the surface, but without the power of rising above or sinking below it, very much like shadows--only hard with luminous edges--and you will then have a pretty correct notion of my country and countrymen.  Alas, a few years ago, I should have said 'my universe,' but now my mind has been opened to higher views of things. ..."\n\nFlatland is very old Hard Science Fiction, if you look at it right.  It's clever, satirical, funny and sad.  It includes well-fleshed-out alien society with similarities to our own, several different alternate universes, genetics, politics, religion, slavery, tyranny, war, rebellion, imprisonment, madness, and death.\n\nAnd math.  And geometry.  And some rather clever Puns.  "Written by A. Square?"  Also known as Edwin Abbott Abbott.  Get it?\n\nAs if the Brothers Grimm had gotten much, much Grimmer.\n\n"To The Inhabitance of SPACE IN GENERAL, And H.C. IN PARTICULAR, This Work is Dedicated By a Humble Native of Flatland, In the Hope that Even as he was Initiated into the Mysteries Of THREE DIMENSIONS, Having been previously conversant With ONLY TWO, So the Citizens of that Celestial Region May aspire yet higher and higher, To the Secrets of FOUR, FIVE, or EVEN SIX Dimensions, Thereby contributing To the Enlargment of THE IMAGINATION, And the possible Development Of that most and excellent Gift of MODESTY, Among the Superior Races Of SOLID HUMANITY."\n\nBring a pencil.  And use your imagination.  I dare you.	http://static.libsyn.com/p/assets/8/b/f/d/8bfd2fdc7275fe56/raw.jpg
2572	http://feeds.feedburner.com/LBCVideoPodcast	Louisiana Baptist Convention Video Podcast	Louisiana Baptist Convention (webmaster@LBC.org)	The LBC Podcast is a collection of videos to equip and encourage Louisiana Baptists. This is an extension of the other services of the LBC. The LBC Podcast is a Cooperative Program Ministry	http://media.lbc.org/video-podcast-logo.jpg
2573	http://podcast.uctv.tv/uctv_business.rss	Business (Audio)	UCTV	From entrepreneurship to economic policies these programs introduce you to leaders and issues in the business community. Visit uctv.tv/business	https://www.uctv.tv/images/itunes/subject-business.jpg
2574	http://recordings.talkshoe.com/rss30735.xml	The Jiggy Jaguar Experience	kjagradio	The Sunday Radio show has been on the air since 1993. If it's Sunday's its The Jiggy Jaguar and Izreal.	https://show-profile-images.s3.amazonaws.com/production/676/the-jiggy-jaguar-experience_1531860336_itunes.png
2575	http://feeds.feedburner.com/VegasGrinders	Vegas Grinders – Pokerati	Michalski, Ferrara, Neeme	We're at the tables every day and night to bring you the best of Vegas poker action every week in easily digestible podcast form.	http://pokerati.com/wp-content/uploads/LVG-2.png
2576	http://feeds.feedburner.com/NationalSoccerRadionsr	National Soccer Radio	JD "Smitty" Smith (ivan.lee@cbsradio.com)	Many in America are hardcore soccer fans, but lack that true outlet that focuses on the game in America. NSR is committed to covering US Soccer and Major League Soccer, and will also cover various other soccer avenues in the country, (NCAA, minor league s	http://cbsnewyork.files.wordpress.com/2010/08/nationalsoccer.jpg?w=195&h=146
2577	http://librivox.org/rss/7638	He Can Who Thinks He Can by MARDEN,  Orison Swett	LibriVox	Do you have what it takes to be the person you want to be? This is a neat self help book in plain English by the New Thought Movement author Orison Swett Marden. He has included various essays on the principles he believes will lead to success in life. This book is a nice reading for any one who believes in "The golden opportunity you are seeking is in yourself. It is not in your environment; it is not in luck or chance, or the help of others; it is in yourself alone," which was one of Orison Swett Marden's famous dialogues. (Summary by sidhu177)	\N
2578	http://lenedgerly.libsyn.com/rss	Audio Pod Chronicles	Len Edgerly	Audio blog of a retired exec who lives in Denver with his wife and Yorkie, and spends time being a grandfather in Cambridge and Boston, with frequent visits to Maine. My interests are family, art, books, movies, quilting, quilts, RV, photos, photography, video, motorhome trips, condo life.  My podcast contains interviews, book and movie reviews, and comments on literature, politics, and popular culture. I am a graduate of Harvard College, Harvard Business School, and the Bennington MFA program in poetry. I have served on the NEFA board - New England Foundation for the Arts - and the Denver Commission on Arts and Culture.	http://static.libsyn.com/p/assets/e/6/8/7/e687d0073387b03d/OnPhoneSquare.jpg
2579	http://www.cbc.ca/podcasting/includes/radio1/dnto/enhanced/index.xml	DNTO (Enhanced)	CBC Radio 1	DNTO invites you to make discoveries about who we really are - flawed, funny, and beautiful - one story at a time.	http://www.cbc.ca/podcasting/images/promo-dnto.jpg
2582	http://www.blogtalkradio.com/ogradio.rss	OG Radio	Organo Gold Radio	Organo Gold was founded on a vision to create a vehicle for the people of the world to be able to reach their full potential. One of the most amazing botanicals	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzL2ZkZTAwM2I1LWI0YmQtNDAzZC1iZjhiLWE5ZGYzYWE4ODU0MG9ncmFkaW9sb2dvLmpwZw/fde003b5-b4bd-403d-bf8b-a9df3aa88540ogradiologo.jpg?mode=Basic
2583	http://tarabrabazon.libsyn.com/rss	Tara Brabazon podcast	Tara Brabazon	Tara Brabazon explores popular culture and education, and the relationship between them.	https://ssl-static.libsyn.com/p/assets/a/7/e/e/a7ee2349ce499fd8/Tara_Brabazon_Podcast.jpg
2584	http://recordings.talkshoe.com/rss85022.xml	US WhoCast	uswhocast	Join your host Matt Murdick in exploring the 2005 reboot of the BBC television series Doctor Who. The podcast blog is at http://uswhocast.wordpress.com	https://show-profile-images.s3.amazonaws.com/production/1692/us-whocast_1531861275_itunes.png
2585	http://vallejozencenter.org/feed/podcast	Clear Water Zendo	Clear Water Zendo	A Soto Zen temple in Vallejo, CA	http://vallejozencenter.org/wp-content/plugins/powerpress/rss_default.jpg
2587	http://www.mhthompson.com/Algebra2/Algebra2Podcast.xml	Mr. T's Algebra Lessons	Mikel Thompson	Podcasts of lessons from Mr. Thompson's algebra 2 class at King's High School in Seattle, WA.	http://www.mhthompson.com/images/math_professor_big.png
2588	http://podiobooks.com/rss/feeds/episodes/heart-of-the-ronin/	Heart of the Ronin	Scribl	Thirteenth-century Japan is a dangerous place, even in a time of peace.  Capricious gods, shape-changing animals, and bloodthirsty demons are as real and unpleasant as a gang of vicious bandits.  From the wilderness emerges a young, idealistic warrior with his father’s mysterious sword on his hip, a wise, sarcastic dog at his side, and a yearning in his heart to find a worthy master.  He dreams only of being samurai. Little does he suspect the agony and glory that await him when his dreams come true.\n\nFinding a master should be easy for a warrior as skilled as Ken’ishi, but the generations-long wars for the Imperial throne have ended.  The land has settled into an uneasy peace and cast multitudes of proud, powerful warriors to the four winds.  The new peace means that these masterless warriors, ronin, often must stoop to crime and banditry to feed themselves.  Ken’ishi finds himself plagued by the hatred and mistrust of peasants and samurai alike.\n\nWhen he saves a noble maiden from a pack of bandits, he and his faithful dog become enmeshed in the intrigues of samurai lords, vengeful constables, Mongol spies, and a shadowy underworld crime boss known as Green Tiger.  But Ken’ishi has a few secret weapons of his own, granted to him by his mysterious past and his magical upbringing.  If only he knew more about his mysterious past, his parents’ murder, and the sword that seems to want to talk to him. . . .\n\nHeart of the Ronin is an action-packed historical fantasy, set against the backdrop of ancient intrigue and impending war, the first of a sweeping three-part epic filled with deadly duels and climactic battles.  Creatures of folklore and myth are as real as the katana in one’s hand.  And just as deadly.\n\n"A fusion of historical fiction and adventure fantasy, the first volume of Heermann's Ronin Trilogy is a page-turning folkloric narrative of epic proportions. In a strange, supernatural feudal Japan, 17-year-old warrior Ken'ishi, a masterless samurai with a mysterious past and a legendary sword, saves the life of Kazuko, a powerful lord's daughter. Soon he becomes entangled in a deadly web of treachery, obsession and vengeance along with a bevy of conspirators, spies, assassins and otherworldly monstrosities. Though Heermann does little to push the boundaries of the subgenre, his writing style is confident and fluid, his characters are well developed and his serpentine story line anything but predictable. Numerous tantalizingly unresolved plot threads will have readers anxiously awaiting the second installment in this gripping tale of ill-fated love, betrayal and destiny. " - PUBLISHERS WEEKLY\n\n"Heart of a Ronin is a solid, likeable adventure story, sure to please fans of Japanese culture, and fantasy readers alike." - ADVENTURES IN SCI-FI PUBLISHING	http://static.libsyn.com/p/assets/6/3/b/d/63bdfc1dd0914919/Heart-of-the-Ronin_Podcast.jpg
2589	http://feeds.feedburner.com/OhNoPodcast	Oh No Ross and Carrie	Ross and Carrie	Welcome to Oh No, Ross and Carrie, the show where we don’t just report on fringe science, spirituality, and claims of the paranormal, but take part ourselves. Follow us as we join religions, undergo alternative treatments, seek out the paranormal, and always find the humor in life's biggest mysteries. We show up - so you don’t have to.	https://image.simplecastcdn.com/images/35621d45-8bc2-42d2-a1f7-8e2805787cb7/24ac9d3f-308b-4e87-9fe4-308e22709782/3000x3000/maxfunpodcasts-coverart-ohnorossandcarrie2-1400px2.jpg?aid=rss_feed
2592	http://www.mactutorial.pl/audio/szarlotka_na_goraco.xml	MacGadka 🎙 – podcast MyApple	Michał Masłowski, Miłosz Staszewski	Co tydzień nasze wrażenia, newsy i recenzje o tym co nowego w świecie Apple	http://www.mactutorial.pl/audio/macgadka1400-lifter-2.jpg
2596	http://feeds.feedburner.com/SlateCultureGabfest	Slate Culture	Slate Podcasts	Get the Culture Gabfest and all of Slate's culture coverage here.	https://images.megaphone.fm/urPQlarpnF-9NaQjsQMdRmZIQPAPiFkxruMxPVXDNiY/plain/s3://megaphone-prod/podcasts/30e9b0ba-8289-11e5-b42a-b725a7afb713/image/uploads_2F1570591152809-jxqh6f8pifh-63a6e312c8f3a56178bb478580b5f694_2FImage%2Bfrom%2BiOS.jpg
2599	http://c.sears.com/ue/home/craftsman.xml	Craftsman Showcase	Sears	Everything you need to know about Craftsman products in a convenient video download.	http://www.craftsman.com/092522/ue/home/logo.CraftsmanMain2.png
2600	http://promodj.com/djgariy/podcast.xml	GARIY aka AGASSI	PromoDJ (podcasts@promodj.com)	«GARIY , обладающий тонким пониманием клубного бизнеса, в России является достаточно ярким персонажем. Занимаясь промоутерской деятельностью, он как никто другой знает, чего хочет публика. GARIY раскачивает танцполы KaZantip'a уже ДЕСЯТЬ СЕЗОНОВ подряд и по праву слывет одним из самых качественных исполнителей стилей house и tech house », - пишет о нем российская пресса.\nDJ GARIY , продюсер , музыкант, креативный промоутер , организатор ярких...	https://cdn.promodj.com/afs/137a58994c37144a13c0a7b31cf2bdd812:resize:1400x1400:same:7ae1d5.jpg
2601	http://feeds.feedburner.com/heywereback	Hey We're Back! Podcast	Jonathan Katz (heywereback@gmail.com)	From the desk of Jonathan Katz: "For the past year or so I've been creating a weekly radio show called 'HEY WE'RE BACK.' The show has featured a number of famous and not-so-famous guests, ranging from music legends like Bob Dylan and Aretha Franklin...to Lewis, the exterminator from Orkin. Using the magic of the internet you can now listen to 'HEY WE'RE BACK' right here!" --- www.jonathankatz.com ---	https://content.production.cdn.art19.com/images/e8/f0/a0/8f/e8f0a08f-ecc8-426b-a832-18feb37e7e4e/d7a3467e90e826c85fa550d47251b9408b5a4ef94fb853dc72de5a2f525086ab0810b4bc288373138494a17088b0149f5364c171730d55857a455431083e1cc5.jpeg
2604	http://promodj.com/zemine/podcast.xml	DJ ZEMINE	PromoDJ (djzemine@yandex.ru)	Мама российской Drum and Bass сцены, тренер спортивно-травматического ансамбля Provansal' Female DJs , владелец WOW Signal Records , участник Казантипа, дизайнер, музыкант, промоутер, автор текстов. \n DJ Zemine играет с 1998 года. До этого была известна как лидер панк-коллектива "Ла-5 в воздухе" и дизайнер клубных перфомансов (коллекция "Дерзость и безвкусица"). C 1999 до 2012 года совладелец, дизайнер и арт-директор лейбла Respect Records и промо-группы...	https://cdn.promodj.com/afs/6a693e2a37dc51838739118209b3de12:resize:1400x1400:same:32fd8a.png
2605	http://feeds.feedburner.com/secondfloorlounge/IKbk	The Second Floor Lounge	silvervale@gmail.com (Erik Ackerman)	Eclectic music that must be shared.	http://www.secondfloorlounge.net/images/logo_large.png
2606	http://www.bible-sermons.org.uk/podcast.php	Bible Sermons Online Podcasts	Greyfriars Free Church Continuing	Reformed, expository bible sermons from Greyfrairs Free Church Continuing, Inverness Scotland. Look for our Podcast in the iTunes Music Store	\N
2608	http://feeds.univ-lyon2.fr/2008_2009-JourneeDoctoriales2008	Journée d'études de l'Ecole Doctorale EPIC (Doctoriales 2008)	Université Lyon 2	Journée d'études de l'Ecole Doctorale EPIC (Doctoriales 2008)	http://farm4.static.flickr.com/3090/3196215401_1da23f8cb0.jpg
2609	http://feeds.feedburner.com/stpetersarlingtonsermons	» St. Peter's Arlington, WI	St. Peter's Lutheran Church	The weekly sermons from St. Peter's Lutheran Church (LCMS) in Arlington, WI	http://stpetersarlington.org/wp-content/uploads/2011/02/St.-Peters-Podcast.jpg
2610	http://www.thebrewingnetwork.com/bnnews.xml	Beer News from The Brewing Network	Justin Crossley	Beer. Brewing Network News coverage of craft beer and homebrewing events and festivals.	http://www.thebrewingnetwork.com/images/iTunesLOGO.jpg
2611	http://toginet.com/rss/itunes/thesociablehomeschooler	The Sociable Homeschooler	Vivienne McNeny	Have you ever wondered how people just like you manage to homeschool their children and apparently love every moment of it?  Are you ready to give up the formative years of your children’s lives to a stranger?  Do you think homeschoolers are weird?  Does the word, homeschool, bring to mind Birkenstocks, jumpers, and hairy legs?  Honestly half my family fit the hairy leg stereotype…so who cares?  I’m here to help you let go of any pre-conceived notions you may have about home educators.  Forget all the excuses ever made under the sun for not homeschooling and listen to my show which is a generous mix of my life as the oxymoron, Sociable Homeschooler, international guests from all walks of life and light hearted views and comments about education and basements.  I will also bend your ear with excerpts from my soon to be published book, also entitled, The Sociable Homeschooler, which chronicles many good causes for why my blue eyed cowboy and I chose to go off the deep end hand in hand with God and have everyone talking about us behind our backs and in the end winning them over.  Come and be won over on Toginet Radio Live on Fridays, if only to get a weekly taste of Britain.	https://toginet.com/showimages/thesociablehomeschooler/sociablehomeschooleriTunes.jpg
2613	http://gmauthority.com/blog/category/podcast/weekly/feed/	Weekly – GM Authority	\N	General Motors News, Rumors, Reviews, Forums	https://gmauthority.com/blog/wp-content/uploads/2017/11/GMA-2015-Logo.jpeg
2614	http://www.trlicious.com/trlicious_rss.xml	DJ TR Licious Mix	DJ TR Licious	Deep Sexy Soulful Funky Club House Music Mix to get you Movin! Let's dance, let's shout, shake your body down to the ground. First on the floor, DJ TR Licious mixes it up for your pleasure. oNe LUv!! Also check out www.myspace.com/trlicious	http://www.trlicious.com/Photo_25.jpg
2615	http://feeds.feedburner.com/USPresidentsPodcast	U.S. Presidents Podcast	LearnOutLoud.com	LearnOutLoud.com presents the U.S. Presidents Podcast. Each episode will provide a brief biographical portrait of each president, explore the eras in which they led the country, and access the historical significance they hold for us today. This is a podcast for those that wish to gain a complete knowledge of the commander in chief.	http://www.learnoutloud.com/podcasts/Podcast-Image-USPresidents300.jpg
2617	http://www.mondaymorningmemo.com/newsletters/podcast	Wizard of Ads	Roy H. Williams	Thousands of people are starting their workweeks with smiles of invigoration as they log on to their computers to find their Monday Morning Memo just waiting to be devoured. Straight from the middle-of-the-night keystrokes of the Wizard himself, the MMMemo is an insightful and provocative series of well-crafted thoughts about the life of business and the business of life.	http://goodies.wizardacademypress.com/woatunes.jpg
2619	http://joshyuter.com/?feed=podcast	YUTOPIA	jyuter@gmail.com (Rabbi Josh Yuter)	Rabbi Josh Yuter podcasts classes on a wide variety of Jewish topics	https://joshyuter.com/wp-content/uploads/powerpress/Profile-Podcast.png
2620	http://www.secretsoundservice.com/loungecast/loungecast.xml	LoungeCast	Louis Salemson	Nothing is as comforting as settling in with a nice drink, while a LoungeCast is floating through the speakers. Secret Sound Service offers flavourful mixes made with calming genres like Lounge, Chillout, Nu-jazz and Downtempo. Experience the relaxing qualities of these soothing ingredients as you sip away the tensions of the day; before bedtime, with your friends or on the couch with your lover. Visit us on www.secretsoundservice.com for previous episodes and join us on Facebook for more info: http://www.facebook.com/secretsoundservice	http://www.secretsoundservice.com/image/center_banner2.jpg
2621	http://feeds.feedburner.com/capitalpc	I'm a PC - 95.8 Capital FM	95.8 Capital FM	Watch stories from the Capital team and Londoners like you.  Find out more at www.capitalradio.co.uk.	http://www.creationpodcasts.com/data/categories/capitalpc/itunescover.jpg
2622	http://feeds.feedburner.com/TechUkPodcast	Tech UK Podcast	Tech UK	Ever wanted to know what has been happening in the UK tech world over the past week? Here's your answer. Plus worldwide tech news to keep you in the loop!	\N
2627	http://www.spreaker.com/show/853217/episodes/feed	bAbA ki 'Yaadon ka Idiot Box'	bArfaNi bAbA		http://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/c578fe8db479d65ea735db3660b1dda5.jpg
2628	http://www.talesbytom.libsyn.com/rss	Tales by Tom	Tom Cagley Sr	The concept behind Tales by Tom is to tell stories---stories that make readers cry and laugh, that amaze and teach and demonstrate, that leave readers wealthier in some way and speak to universal traits, like the joy we all experience seeing people reunited after decades of separation.	https://ssl-static.libsyn.com/p/assets/8/8/7/7/887742c433900d06/Even_the_Day_Artwork.jpg
2631	http://feeds.feedburner.com/Hosed	Hosed	Juston McKinney (hosedtv@gmail.com)	A comedy series about a volunteer fire department in Effingwoods NH.  In this episode Ben (Juston McKinney) and Smitty (Gary Valentine) respond to a fire call.  This episode co-stars Lenny Clarke (Rescue Me).	http://a.images.blip.tv/Hosedtv-300x300_show_image204.png
2634	http://www.hp.com/hpinfo/podcasts.xml	Hewlett-Packard Podcasts and Vodcasts	\N	Listing of podcasts and vodcast/videocasts available from Hewlett-Packard (HP).	http://www.hp.com/hpinfo/podcasts/images/podcastlogo.jpg
2635	http://unspokentruths.podOmatic.com/rss2.xml	Unspoken Truths Podcast	Unspoken Truths		https://unspokentruths.podomatic.com/images/default/podcast-4-1400.png
2637	http://vandiemen.podomatic.com/rss2.xml	My house is your house	vanDiemen	This is a collection of electronic music ranging from tech, deep to dark tribal & progressive. Big DJ talent of influence includes: John Digweed, Sasha, Eric Prydz, Pete Tong & Deep Dish. I extend a big thank you to all my followers.	https://assets.podomatic.net/ts/13/c9/16/vandiemen/3000x3000_5771922.jpg
2638	http://www.spreaker.com/show/462479/episodes/feed	Geek llamando a Tierra	macharley72	Un manzanero harleryano que quiere compartir experiencias tecnológicas con otros geeks y meeks.	http://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/fb552a918d2e985e1c991ef8f52431fc.jpg
2640	http://librivox.org/rss/4058	Believe Me, if All Those Endearing Young Charms by MOORE, Thomas	LibriVox	LibriVox volunteers bring you 17 recordings of Believe Me, If All Those Endearing Young Charms by Thomas Moore. This was the Weekly Poetry project for February 14th, 2010.	\N
2641	http://feeds.feedburner.com/podbean/fBAq	XP PSP	Dave Cunning (just_playin_the_game@yahoo.com)	a bunch of expat guys who live in Korea and love sports sitting around and talking about them for half an hour.	https://pbcdn1.podbean.com/imglogo/image-logo/615707/XPPSPlogo.jpg
2642	http://www.fourserver.com/podcast/podcast_eng.xml	English Version: Four Music, Yo Mama, Fine, Nesola  & BPX 1992 Videopodcast	fourmusic.com	Your favorite podcast. Videoclips, interviews and information from Four Music / Fine / Yo Mama / Nesola / BPX 1992	http://www.fourserver.com/podcast/logos.jpg
2643	http://momotek.podomatic.com/rss2.xml	Tweekin Ur Soul Podcast	Tovar aka Momotek	"Tweekin Ur Soul Podcast Series" Serving you a 60 min' mix of the best [House-TechHouse-DeepHouse-Min-Techno] each month, including many of my special edits. Stay Tuned for "music for your body and soul".\n\nwww.twitter.com/TovarNYC\nwww.facebook.com/TovarNYC\nwww.soundcloud.com/TovarNYC\nhttp://dj.beatport.com/TovaNYC\nwww.facebook.com/TovarNycOfficial\nSubscribe to "Tweekin Ur Soul Podcast" at:\nwww.momotek.podomatic.com Click the iTunes icon..\n\nFor Info & Bookings:\nmomotek@live.com \ntweekinursoul@gmail.com	https://assets.podomatic.net/ts/b7/1f/41/momotek/3000x3000_8109891.jpg
2645	http://du.libsyn.com/rss	Dispatches from the Underground	Joey Steel	On Dispatches from the Underground host NYC punk Joey Steel, and guests explore the depths of underground, sub, and counter-culture while also trying to grasp a UG perspective on the mainstream and pop culture we are subjected to endure. Dig deep/Get down.	https://ssl-static.libsyn.com/p/assets/d/0/b/9/d0b957784f4e9e3c/Dispatches_fromt_the_Underground_SQUARE_image.jpg
2647	http://www.d3blogs.com/d3football/?feed=podcast	D3football.com » D3football.com Around the Nation Podcast	D3football.com, Pat Coleman and Keith McMillan	The daily dish on Division III football.	http://www.d3blogs.com/wp-content/blogs.dir/15/d3fbrss.jpg
2649	http://gehsapbio.podbean.com/feed/	AP Biology--GEHS	Mr. Sutton	New podcast weblog	https://pbcdn1.podbean.com/imglogo/image-logo/10847/logo2.jpg
2650	http://www.vbprice.com/podcasts/podcast.xml	V.B. Price - Poet and Author	V.B. Price	From Albuquerque, New Mexico USA: Poems and prose about New Mexico, the environment and much more	http://www.vbprice.com/podcasts/vb_price_144.jpg
2651	http://sermon.net/rss/fbcLosAlamos/main	First Baptist Church Los Alamos	FBCLA	First Baptist Church Los Alamos (FBCLA) is church that loves to see Jesus transform people's lives. We are located in Los Alamos, New Mexico. www.fbc-la.org	http://storage.sermon.net/e404715e0118afbfddc2522ed3482aa3/0-0-0/content/media/47336/artwork/d7520f8f2989dedb50f6879741eb09ac.jpg
2653	http://monsterfeet.com/noquarter.rss	No Quarter	Monster Feet	Mike Maginnis and Carrington Vanston discuss and review classic arcade games.	http://monsterfeet.com/artwork/itunes/itunes_noquarter.png
2655	http://promodj.com/Ange/rss.xml	ANGE	PromoDJ (ira.ange@gmail.com)	Ira Ange (Top 100 Russia)\nDjane, vocalist, soundproducer since 2008.\nResident of Plastic City, Baroque, Black Hole Recordings, Dear Deer Record Labels	https://cdn.promodj.com/afs/7f1f72fa170e16833dcca219d4db625011:resize:1400x1400:same:3ea137.png
2656	http://versusbulls.podOmatic.com/rss2.xml	versusbulls's Podcast	versus bulls		https://versusbulls.podomatic.com/images/default/podcast-4-1400.png
2657	http://idpodcast.podomatic.com/rss2.xml	ID Podcast	Infinite Dimensions	Once a month the ID cast sits down and talks about everything from upcoming video games, to Frank!	https://assets.podomatic.net/ts/b8/9c/39/cbarrington776/3000x3000_5982868.jpg
2658	http://feeds.feedburner.com/Calvary/sermons	Sermons – Calvary Baptist Church	Amy Butler	Sermons of Calvary Baptist Church in Washington, DC.	http://www.calvarydc.org/wp-content/uploads/2011/08/better-together-e1315105141288.jpg
2659	http://feeds.feedburner.com/sfcgp	Ignition: A Podcast for the New Evangelization	Dr. Chris Burgwald (cburgwald@sfcatholic.org)	Catholic Godcasting from the Prairie (CGP) is a production of the Adult Faith Formation Office of the Catholic Diocese of Sioux Falls. CGP provides explanations of Catholic teaching and a Catholic perspective on issues of the day.	http://www.sfcatholic.org/Archives/Audio/media/Ignition/tmp_ignition_podcast_cover.jpg
2660	http://feeds.feedburner.com/MetisDjQmRupromodjcom/metis-dj	METIS	PromoDJ (booking.metis@gmail.com)	----- METIS DJ - музыкант и мультиформатный диск-джокей, за плечами которого уже 10 лет гастролирования на площадках России. \n Входит в состав группы Atlantis Ocean (Moscow) promodj.com/AO . Участик нашумевшего фестиваля Trancemission. Частый гость Москвы и других городов России. \n ----- METIS ----- в первую очередь, позитивный заряд "новой волны" которую пускает на танцпол. Природное очарование и лучшие HOUSE|TECHNO хиты, гарантировано взрывают любые танцполы....	https://cdn.promodj.com/afs/ef6b42c7009de8e8ddba1b95e154487811:resize:1400x1400:same:5cc988.png
2662	http://feeds.feedburner.com/Signal-Integrity-Tips	Signal Integrity	Colin Warwick, Agilent EEsof EDA	Signal Integrity for Multigigabit/s Serial Links from the Agilent EEsof EDA signal integrity group. This podcast edition of our blog --http://signal-integrity.tm.agilent.com -- is about tips, tricks, and tutorial to help ensure signal integrity on chip to chip serial links.	http://signal-integrity.tm.agilent.com/wp-content/uploads/si_podcast.jpg
2663	http://recordings.talkshoe.com/rss24724.xml	Your Identity in Jesus Christ	onehundredgees	Welcome to YOUINHD, Your Identity in Jesus Christ my name is Erick Miller, lay preacher, pastor and evangelist for Elm Tree Ministries. Sound bible teaching and preaching is so critical to Christian growth in today landscape and YOUINHD is committed to preaching the truth of JESUS CHRIST. Sharing the gospel one episode at a time.	https://show-profile-images.s3.amazonaws.com/production/927/your-identity-in-jesus-christ_1531860503_itunes.png
2664	http://feeds.feedburner.com/mydailyphrasegerman	My Daily Phrase German	Radio Lingua Network	Learn German with teacher Catriona from the Radio Lingua Network. In 100 lessons you will pick up the basics of the German language step by step, day by day, phrase by phrase.	http://radiolingua.com/images/1400/mdpg-2012-1400.jpg
2665	http://www.centerforgospelculture.org/wp-content/themes/centerforgospelculture/podcast.php/	Stephen Um's Podcast	Tim Chang		http://www.centerforgospelculture.org/wp-content/themes/centerforgospelculture/img/podcast_icon.jpg
2667	http://feeds.feedburner.com/praytherosaryupdated	Pray The Rosary	Donald Crescenzo, M.D.	Audio Podcast to pray the rosary using the correct Mysteries	https://feedburner.google.com/fb/images/pub/fb_pwrd.gif
2671	http://feeds.feedburner.com/expmedpod	Experimental Medicine: Libertarian News, Politics, and Pop-Culture	blakeoates@gmail.com (Blake A. Oates)	A libertarian commentary on news, politics, and pop-culture.  www.ExpMed.net	http://www.angelfire.com/indie/tragicwaste/BulbLogo.jpg
2672	http://librivox.org/rss/4215	Elements of Style, The by STRUNK, JR., William	LibriVox	“The Elements of Style (1918) by William Strunk, Jr. is an American English writing style guide. It is one of the best-known and most influential prescriptive treatment of English grammar and usage, and often is required reading in U.S. high school and university composition classes. The original 1918 edition of The Elements of Style detailed eight elementary rules of usage, ten elementary principles of composition, “a few matters of form”, and a list of commonly "misused" words and expressions. This book, printed as a private edition in 1918 for the use of his students, became a classic on the local campus, known as "the little book", and its successive editions have since sold over ten million copies. This version is based on the public-domain text from 1918, which was originally uploaded to Wikibooks and wikified by Wikibooks:User:Lord Emsworth in 2003. In January 2006, Kernigh transwikied the text from Wikibooks:Elements of Style to Wikisource.” (Summary by Wikipedia and Wikisource)	\N
2673	http://podiobooks.com/rss/feeds/episodes/noggle-stones/	Noggle Stones	Evo Terra	In this podiobook: Shunned by his people and tormented by nightmare visions, Bugbear, the mad goblin scholar, ventures into the wilderness with his ne'er-do-well cousin, Tudmire, to seek out an ancient ruin and the lost wisdom it holds.Soon the cousins find themselves embroiled in cosmic events as their magical world of Annwfn is merged with 19th Century Earth after an accident concerning a mysterious scroll Tudmire acquires in a crooked game of Noggle Stones. While fleeing the enraged ogres they cheated, Bugbear and Tudmire happen upon Martin Manchester, who appears to be a creature of mythology known as a human. Bugbear takes Manchester as his apprentice, agreeing to teach him the empowering ways of Non-Logical Thought.  The trio soon discovers that dark forces have aligned against them, and the two worlds may have been merged only to be destroyed!	http://static.libsyn.com/p/assets/8/3/9/3/839388ea816c8a94/NoggleStones.jpg
2676	http://forerunnernation.podomatic.com/rss2.xml	Forerunner Nation Podcast	Forerunner Nation	Forerunner Nation.  Thats the Fun I Have.\n\nWe talk about Halo, life and being a member of Forerunner Nation.	https://assets.podomatic.net/ts/36/3f/2a/saintchristoph/1400x1400_8209108.jpg
2680	http://webtalkradio.net/internet-talk-radio/category/podcasts/brainstorms/feed/	WebTalkRadio.net	\N	The Best Internet Radio. The Future of Talk Radio. It's Web Talk Radio.	https://webtalkradio.s3.us-east-2.amazonaws.com/2020/07/cropped-favicon-32x32.jpg
2681	http://feeds.feedburner.com/ramjack	Ramjack	Alexander Green and Brad Cupples (ramjackpodcast@gmail.com)	Brad Cupples and Alexander Green tackle tomfoolery, shenanigans, and goings-on in an unyielding quest to deliver a little thing the kids like to call "infotainment" Every week we discuss news, events, and/or personal anecdotes as well as review the finest sitcoms of the 80s in an attempt to learn from their often hidden virtues. Bangarang!	http://ramjackpodcast.com/newRamjackCover.png
2682	http://www.tfw2005.com/boards/external.php?type=rss2&forumids=404	WTF @ TFW – The TFW2005 Transformers Podcast	wtf@tfw2005.com (WTF @ TFW – The TFW2005 Transformers Podcast)	WTF @ TFW is a Podcast by Transformers fans from fan site TFW2005.com. Features topics related to everything in the Transformers universe. Includes news round-ups and discussion on the new Transformers movie, Transformers toys, talk and discussion on TFW2005's 2005 Boards, and more!	http://wtf.tfw2005.com/wp-content/uploads/sites/15/powerpress/wtf_tfw_tfw2005_podcast.png
2686	http://reviewcentralhd.podomatic.com/rss2.xml	ReviewCentralHD Podcast	Bolea	A weekly podcast made by ReviewCentralHD and Underground Garage Music featuring the latest technology news, rumors, and general discussion.	https://assets.podomatic.net/ts/42/b2/5d/reviewcentralhd/3000x3000_7023871.png
2687	http://untouchabledjdrastic-kcash-reedrichards-bcat-hq.podomatic.com/rss2.xml	BCAT Podcast(s) – Untouchable DJ Drastic | K. Cash (Kevin McKessey) | Reed Richards	Daniel M. Johnson | The Untouchable DJ Drastic	Radio Nation & The Coalition Network {TCN²} present syndicated podcast(s) from hosts, The Untouchable DJ Drastic, K. Cash (Kevin McKessey), & Reed Richards. Subscribe to all of The Untouchable DJ Drastic, K. Cash (Kevin McKessey), & Reed Richards’ syndication podcast(s) from various broadcast media outlets. Unauthorized use of this or any podcast is strictly prohibited. Violators are punishable under federal law. For all additional information and/or inquiries contact The Coalition Network {TCN²} Management Group @ (702) 560-1050 or TCNManagementGroup@gmail.com!	https://assets.podomatic.net/ts/08/22/a3/djdrasticbcat/1400x1400_3375451.jpg
2688	http://www.buzzsprout.com/4457.rss	Misjonskirken Stavanger's Podcast	Misjonskirken Stavanger	Gikk du glipp av talen på søndag? Vil høre den igjen? Ved hjelp av vår nye podcast-tjeneste kan vi endelig gjøre talene tilgjengelig på hjemmesiden vår,.Tips: du kan også abonnere på vår Podcast via Itunes!	https://storage.buzzsprout.com/variants/N6CAYWWHUUMSpgeRnPSFZVM4/8d66eb17bb7d02ca4856ab443a78f2148cafbb129f58a3c81282007c6fe24ff2?.jpg
2689	http://podiobooks.com/rss/feeds/episodes/the-id-files/	The ID Files	Evo Terra	In this podiobook: The ID Files is a compilation of interviews about the recent Intelligent Design Controversy taken from The Sci Phi Show (http://thesciphishow.com). These interviews are with Dr Michael Shermer of the Skeptic Society, Salvador Cordova of the IDEA Centre, Dr Mike Behe of Lehigh University and Nick Matzke from the NCSE. The individuals represent a spectrum of positions on the question of Intelligent Design and these interviews serve as a useful introduction to the issues at stake and the ideas involved.	http://static.libsyn.com/p/assets/1/3/0/c/130c1d1422e74527/raw.jpg
2691	http://www.podcast.catholic.net/rss/privero.xml	Catholic.net - El Rosario meditado - P. Antonio Rivero	Catholic.net Inc.	El Padre Antonio Rivero nos ofrece unas hermosas reflexiones del Rosario y su importancia en la vida de cada hombre y de la Iglesia. Los interesados encontraran valiosas meditaciones de los principales misterios de nuestra fe.  Para los lunes y los sabados corresponde rezar los misterios gozosos, los jueves los luminosos, los martes y viernes los dolorosos y los miercoles y domingos los gloriosos.	http://www.podcast.catholic.net/imagenes/logo_podcast.jpg
2693	http://feeds.feedburner.com/vc/podcast	Village Church – Kelvin Grove	Village Church (info@vc.org.au)	Village Church Kelvin Grove Weekly Talks	http://vc.org.au/wp-content/uploads/2014/05/V-1440.png
2694	http://www.wunderbar-recordings.com/rss/rss_itunes.xml	WunderBar Recordings Podcast	WunderBar Recordings	Official Monthly Podcast, pres. by WunderBar\n    Recordings	http://www.wunderbar-recordings.com/podcast/logo.jpg
2695	http://podcast33087.podOmatic.com/rss2.xml	Kyle Burleigh's Podcast	Modcast	This is a podcast discussing different guitar mods.	https://assets.podomatic.net/ts/be/ba/ae/podcast33087/1400x1400_3002798.jpg
2696	http://www.rzim.org/let-my-people-think-broadcasts/feed/	RZIM: Let My People Think Broadcasts	rzim.org	Half-hour programs heard weekly. The radio outreach of RZIM is a listener-supported ministry that powerfully mixes biblical teaching and Christian apologetics. The programs seek to explore issues such as life's meaning, the credibility of the Christian message and the Bible, the weakness of modern intellectual movements, and the uniqueness of Jesus Christ.	https://s3-us-west-2.amazonaws.com/rzimmedia.rzim.org/2020_LMPT_icon_1500.jpg
2697	http://feeds.feedburner.com/NerdLovePodcast	Paging Dr. NerdLove	Harris O'Malley (homalley@doctornerdlove.com)	Doctor NerdLove is here to help you get your dating life in order with the best dating advice and positive masculine self-improvement on the Internet. \r\n\r\nDoctor NerdLove is not really a doctor\r\n\r\nDoctor NerdLove is not really a doctor	http://www.doctornerdlove.com/wp-content/uploads/2016/09/NerdLoveSqLogo_Color_Web.gif
2701	http://www.blogtalkradio.com/christinelu.rss	@ THE INTERSECTION	Archive	Standing at the intersection of life crossing paths with some really interesting, inspiring and influential people along the way. To tweet comments & questions related to this show, use hashtag #clu in Twitter.	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/48c3c21b4f2d0dfea5e15ae65f7547b8.jpg
2702	http://feeds.feedburner.com/TouchdownAirbase	Airbase	Airbase	Podcast by Airbase	http://i1.sndcdn.com/avatars-000114026568-slykee-original.png
2703	http://stevepitronsessions.podomatic.com/rss2.xml	STEVE PITRON HOUSE SESSIONS	Steve Pitron	PRS Licence Number:: LE-0006022::\nRegular podcast sessions featuring some of the most upfront house tracks around creatively mixed together - bringing the clubbing experience to your home/i-pod/car....\n\nDownload them all and make sure you subscribe to these sessions to ensure you get the latest ones as soon as they're released.\n\nPlease leave your comments - much appreciated....\n\nYou can catch me spinning at London clubs that inc. BEYOND, FIRE, Lo Profile, Room Service as well as one off parties like the WE party from Spain. \n\nContact me on Facebook and follow me on Twitter...\n\nThanks for the support!	https://assets.podomatic.net/ts/ca/2d/cd/stevepitronsessions/3000x3000_10222748.jpg
2705	http://feeds.feedburner.com/93xsports	No Data Found	93X Half-Assed Morning	Minneapolis, Minnesota's, 93X Half Assed Morning Show 7:30 Sports Update with KARE 11's Randy Shaver	http://rope.93x.com/feeds/assets/SPORTSUPDATE.png
2708	http://irishflute.podbean.com/feed/	Irish Flute Tunes	Michael Clarkson	Traditional Irish Flute Tunes\n (iflute@googlemail.com)	https://pbcdn1.podbean.com/imglogo/image-logo/6501/newpicture.jpg
2711	http://www.blogtalkradio.com/dentaldoctalk.rss	Dental Doc Talk	Archive	Dr. Mike Abernathy, Max Gotcher, and Jonathan Moffat go beyond talking about the current issues facing todays dentists; they give answers to them. Every episode will discuss things you can immediately take and implement in your practice to start getting better results and make more money. If you would like one on one advice regarding any of the topics we talk about you can email Jonathan at <a href="mailto:jmoffat@ddsstrategies.com">jmoffat@ddsstrategies.com</a> . Don't forget to subscribe to our station.	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/9909c29bc294de330a011e1c7fce37cc.jpg
2712	http://feeds2.feedburner.com/KgggkRadio	Kgggk-radio	kgggk.radio@gmail.com	Willem, Jasper en Ralph gaan, gewapend met een audiorecorder hun nieuwsgierigheid achterna.	\N
2713	http://www.raidionalife.ie/podcast/pros.xml	Prós na hArdteistiméireachta	Raidió Na Life	Sraith nua de dheich gclár ar Raidió na Life 106.4FM ag plé leis an gcúrsa Próis agus le gnéithe eile de chúrsa Gaeilge na hArdteiste. Tá cuid de na húdair le cloisteáil ag léamh sleachta as a saothair féin sa tsraith seo, mar shampla, Máire Mhac an tSaoi ag léamh a gearrscéal “An Bhean Óg” agus Maidhc Dainín Ó Sé ag léamh sleachta as “A Thig Ná Tit Orm”. I gcásanna eile is aisteoirí atá ag léamh míreanna atá ar an siollabas, mar shampla, Lig Sinn i gCathú le Breandán Ó hEithir, á léamh ag Mac Dara Ó Fatharta agus Tetrarc na Gaililí le Pádraig Ó Conaire, á léamh ag Diarmaid de Faoite. \n\nTá na míreanna éagsúla atá ar an gcúrsa litríochta, An Bhéaltriail, an Triail Chluastuisceana, Ceapadóireacht srl á bplé agus á gcíoradh ar gach clár, ag paineál de mhúinteoirí go bhfuil taithí na mblianta acu ag plé leis an siollabas seo.	http://www.raidionalife.ie/images/leabhar3.jpg
2716	http://yong3503.dothome.co.kr/podcast/rss.xml	책관찰자	KWON Soon-yong	book podcast	http://yong3503.synology.me/podcastgen/images/itunes_image.jpg
2720	http://www.blogtalkradio.com/theromanshow.rss	The Roman Show	rodolforoman	Our show will include various topics in mixed martial arts and current events.	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzLzczODkwZWQ3LWI4NTQtNDEzYi1iNDJiLTM3MjU2MmViMDdjNl9qdGZfMTY4OC5qcGc/73890ed7-b854-413b-b42b-372562eb07c6_jtf_1688.jpg?mode=Basic
2724	http://feeds.feedburner.com/12StepPodcast	12 Step Podcast	12 Step Podcast	This is a weekly release of 12 Step audio from many different 12 step groups, however mostly AA groups. This will not be one person sharing their wisdom but instead many different mp3's of many different people who have been working the 12 step program.	http://www.nitecrawler.net/~levis/12steppodcast.jpg
2725	http://www.waitingforgaetjens.com/wfgrss.xml	Waiting for Gaetjens American Soccer Show	Waiting for Gaetjens (podcast@waitingforgaetjens.com)	Greg Lalas and Adam Spangler talk about American soccer. From MLS to the US National Team, Greg and Adam cover it all, with exclusive interviews, witty banter, and all the bells and whistles (a lot of whistles) you could want. Are you Waiting for Gaetjens?	
2726	http://librivox.org/rss/7510	Narrative of My Captivity Among the Sioux Indians by KELLY,  Fanny	LibriVox	"Narrative of my captivity among the Sioux Indians: with a brief account of General Sully's Indian expedition in 1864, bearing upon events occurring in my captivity"\n\n"I was a member of a small company of emigrants, who were attacked by an overwhelming force of hostile Sioux, which resulted in the death of a large proportion of the party, in my own capture, and a horrible captivity of five months' duration. Of my thrilling adventures and experience during this season of terror and privation, I propose to give a plain, unvarnished narrative, hoping the reader will be more interested in facts concerning the habits, manners, and customs of the Indians, and their treatment of prisoners, than in theoretical speculations and fine-wrought sentences." (Summary from Introduction)	\N
2727	http://feeds.feedburner.com/TheCollectiveNetwork	The Collective Network	Collective Network	- The Collective Show\r\n- The Super Awesome Film Show\r\n- KoopaTalkLive\r\n- The Collective Bull***t Sessions	http://i135.photobucket.com/albums/q123/jutin77/bullshit_session_inverted.jpg
2728	http://rowie.podomatic.com/rss2.xml	Rowie (Melbourne, Aus)	ROWIE	For bookings email james@kissmestupid.co	https://assets.podomatic.net/ts/c2/58/8f/djrowie/3000x3000_8754232.jpg
2729	http://feeds2.feedburner.com/CdBabyHipHopPodcast	CD Baby Hip Hop Podcast	CD Baby	Kickin' like a kick drum, the CD Baby Hip Hop Podcast is an all-encompassing look–or listen, if you will–at some of the best hip hop and rap music CD Baby has to offer. Our catalog represents a diverse mix of styles from around the globe, so each episode will take aim at a specific genre, sub-genre, or uniting theme (regional sounds, etc.) that ties the music together. CD Baby hip hop editor Brad digs through the crates, hosting each installment and helping you find some great new music.	http://musicdiscovery.cdbabypodcast.com/images/gray-shine-logo-300.jpg
2730	http://downloads.bbc.co.uk/podcasts/southyorkshire/toby/rss.xml	The Toby Foster Podcast	BBC	The funniest bits of the week from Toby’s weekday breakfast show on BBC Radio Sheffield, with topical chat and the best callers in local radio!	http://ichef.bbci.co.uk/images/ic/3000x3000/p08rl46m.jpg
2731	http://promodj.com/koost/podcast.xml	Kustovsky	PromoDJ (koo100@rambler.ru)	Его имя за долгие годы ди-джейской карьеры стало поистине культовым в южной столице.На его сеты приходят и студенты и клаберы со стажем.Его знают и уважают все,кто ночью предпочитает сну безудержные вечерины.Он стоял у истоков развития нашей клубной культуры,сделав для неё довольно много,воспитав целое поколение ростовских музыкантов и тусовщиков. \n ( DJ Mag Юг) \n Самое именитое и уважаемое действующее лицо клубной культуры города Ростова...	https://cdn.promodj.com/afs/240880354af92c2f50835496a0a780d6:resize:1400x1400:same:fc4958.png
2734	http://www.ricardo-vargas.com/en/?feed=podcast	5 Minutes Podcast with Ricardo Vargas	Ricardo Viana Vargas (info@ricardo-vargas.com)	5 Minutes Podcast is a Ricardo Vargas creation that intends to present and debate the main news and themes in the project management field, in a practical and easy way.	https://static.feedpress.com/logo/5pmpodcast_en-5e1712967b581.png
2735	http://feeds.feedburner.com/dinobrain	Dinobrain!	Dinobrain!	Dinobrain is 'comedy' podcast 'starring' Bee, Mike, and Dave from 'Chicago'. Come doofus around with us!	http://www.dinobrain.com/img/dinobrain_cover.jpg
2736	http://video.rutv.ru/rss/brand/id/5204/rsstype/itunes/	Вести. Дежурная часть	RUTV	Программа создана в 2002 году и с тех пор непрерывно развивается. Неизменно одно – стремление точно и оперативно рассказывать о происшествиях в стране и мире, помогать людям, попавшим в беду.	http://cdn.static1.rtr-vesti.ru/vh/pictures/o/304/213/7.jpg
2737	http://www.blogtalkradio.com/deporteenmente.rss	Deporte en Mente	Archive	Sports Talk Radio in Espanol. Deporte en Mente is back in 2009! <br /><br />Deporte en Mente es el futuro de los deportes en radio hablada. El programa es conducido por el respetado periodista de Fox Sports, Tv Azteca, y comentarista de la NFL, Adrian Garcia Marquez. Adrian es la voz del beisbol en Fox Sports en Espanol al igual que el conductor del programa Impacto NFL. Tambien es el narrador de Box Azteca presentado por Top Rank Boxing, y comentarista en radio de los Chargers de San Diego. Junto a Garcia Marquez esta el reconocido y popular Joel Bengoa, que aporta su estilo unico, el estilo que lo ha hecho la sensacion de los ultimos Superbowls, partidos de la seleccion Mexicana,juegos de los Lakers de Los Angeles, como otros eventos deportivos. Bengoa ha cubierto al Tricolor, el Beisbol de Grandes Ligas, la NFL, y el boxeo, siempre dandole su toque especial a sus reportajes. Deporte en Mente es una hora cargada de energia, opiniones, y puntos de vista educados, hechos por una rotacion de los mejores periodistas del habla hispana en el pais. La revolucion de radio hablada en espanol comienza ya!	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/085c1bf1235a2fccef449a5d1abf44c0.jpg
2739	http://librivox.org/rss/2030	Frankenstein; or The Modern Prometheus (1818) by SHELLEY, Mary Wollstonecraft	LibriVox	Frankenstein; or, The Modern Prometheus is a novel written by the British author Mary Shelley. Shelley wrote the novel when she was 18 years old. The first edition was published anonymously in London in 1818, and this audiobook is read from that text. Shelley's name appeared on the revised third edition, published in 1831. The title of the novel refers to the scientist, Victor Frankenstein, who learns how to create life and creates a being in the likeness of man, but larger than average and more powerful. In modern popular culture, people have tended to refer to the Creature as "Frankenstein" (especially in films since 1931), despite this being the name of the scientist, and the creature being unnamed in the book itself. Frankenstein is a novel infused with elements of the Gothic novel and the Romantic movement. It was also a warning against the "over-reaching" of modern man and the Industrial Revolution, alluded to in the novel's subtitle, The Modern Prometheus. The story has had an influence across literature and popular culture and spawned a complete genre of horror stories and films. It is arguably considered the first fully-realised science fiction novel and raises many issues still relevant to today's society. (Summary from wikipedia.org, adapted by Cori Samuel.)	\N
2742	http://feeds.feedburner.com/LostUnlockedFeed	Lost Unlocked Feed	Chris & Brian	Chris and Brian take a spoiler-free look at the hit television series Lost. Expect a lot of goofball humor and organ sounds!	http://img505.imageshack.us/img505/7771/lulogopi4.jpg
2745	http://radiosf.podOmatic.com/rss2.xml	radioSF:	radioSF	documenting the evolution of music in the Bay Area. check back frequently for new live sets and studio sets by some of the Bay Area's best DJ's and top bands. This is your place to find out what is happening with music in the Bay. peace...	https://assets.podomatic.net/ts/52/f2/7b/radiosf/3000x3000_916873.jpg
2751	http://www.zymogen.net/releases/zym016/podcast/itunespodcast.xml	zym016	zymogen .net label	Zymogen celebrates its second anniversary with a release composed by Marihiko Hara, from Kyoto, Japan.\nHere we have one of the most interesting young Japanese producers to date, also a member of the experimental-pop collective, Rimacona-Lab.	http://www.zymogen.net/upload/podcast_data/zym016_300.jpg
2759	http://feeds.feedburner.com/MrnClassicRaces	MRN Classic Races	Motor Racing Network (cmoore@mrn.com)	Classic race broadcasts from the vault of The Motor Racing Network	https://www.mrn.com/wp-content/uploads/sites/17/2017/12/ITunes-Classic-Races-v1.png
2760	http://feeds.feedburner.com/WELSStreamsPodcasts	WELS text mashup	WELS	You'll find devotions, Bible readings, and ministry related messages from technology to personal interviews or mission field experiences.	http://wels.net/wp-content/uploads/smartcast/1400WELSiTunes.jpg
2761	http://feeds.feedburner.com/kylemaguire	Kyle Maguire	Kyle (kyle@impodcast.tv)	This is Kyle Maguire's podcast! Email him at kyle@impodcast.tv	http://macgeekworld.wordpress.com/files/2008/06/picture-21.jpg
2763	http://feeds.feedburner.com/ZionLutheranMessage	Zion Schumm - Message	Zion Lutheran Church - Willshire, OH  (LCMS)	ZionSchumm.org Proclaiming a Changeless Christ for a Changing World! LCMS	http://www.zionschumm.org/glassart.jpg
2764	http://raneem.podomatic.com/rss2.xml	The Raneem Podcast	Raneem	Raneem brings you a monthly 1-hour mix of his favourite selections of recent electronic dance music releases on The Raneem Podcast\n\ndjraneem.com\nfacebook/djraneem\ntwitter/djraneem\nsoundcloud/raneem\nbandsintown/Raneem	https://assets.podomatic.net/ts/ce/04/2b/info76774/pro/3000x3000_11183370.jpg
2765	http://publicaffairs2point0.eu/category/podcasts/feed/	Public Affairs point	\N		\N
2767	http://theinvestorsparadigm.libsyn.com/rss	The Wealth Standard – Empowering Individual Financial Independence	Patrick Donohoe	We live in the most revolutionary and inspiring time in history, yet our culture settles for a mediocre life, not the one they dream about and deserve.  \n\nThe Mission of The Wealth Standard Podcast is to empower you to take control of your life, your career, and your wealth and to ultimately achieve financial independence. \n\nSociety has programmed us to take orders, from our educational system to the way we save and invest.\n\nAnd what is the incentive? To someday, retire? \n\nIf 1987, 2001, and 2008 weren’t red flags that caused you to question conventional wisdom, I hope 2020 is enough to ask better questions. \n\nJoin host Patrick Donohoe, best-selling author, CEO, and financial advisor as he empowers you to implement the principles, processes, and strategies - and live financially free.	https://ssl-static.libsyn.com/p/assets/4/8/b/c/48bc94171d6e2b13/Podcast_ITunes_Image.jpg
2768	http://www.nirankari.com/rss/hhdiscourses_podcasts.rss	Nirankari Baba Ji Discourses Podcast Channel	Sant Nirankari Mission	Nirankari Baba Hardev Singh Ji is the spiritual guide for Sant Nirankari Mission. The Sant Nirankari Mission is an all embracing spiritual movement, cutting across all divisions of caste, color, and creed.	http://www.nirankari.com/rss/images/babaji_portait.jpg
2772	http://www.blogtalkradio.com/zen-mommies.rss	The Zen Mommies Radio Show	zenmommies	Are you overwhelmed by the many challenges you face as a mom?\n\nDoes your physical weight stop you from creating a successful career and life?\n\nDo you feel s	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzLzM4ZmMxZDRlLWEzNjAtNDhlZC04MTFmLWI4YTgyMGU0YTVhMF9sb2dvLmpwZw/38fc1d4e-a360-48ed-811f-b8a820e4a5a0_logo.jpg?mode=Basic
2775	http://feeds.tsf.pt/Tsf-Runners	TSF - TSF Runners - Podcast	TSF (tsf@tsf.pt (TSF Radio Notciais))	Tudo o que se passa no mundo da corrida. Notícias, dicas de saúde, de nutrição, de locais para correr, de provas.	http://www.tsf.pt/favicon.ico
2776	http://tellsomebody.libsyn.com/rss	Tell Somebody	KKFI-FM 90.1 (Tom Klammer)	Weekly public affairs program on KKFI-FM 90.1, Kansas City community radio	https://ssl-static.libsyn.com/p/assets/7/4/6/8/7468649a4453650a/tslogo1400.jpg
2779	http://www.buzzsprout.com/7135.rss	Trick or Treat Radio	Trick or Treat Radio	Trick or Treat Radio is the world’s most dangerous podcast! They discuss at least one film a week, argue, make fun of each other and hope to make you laugh, some hosts might even die trying. Trick or Treat Radio has been rated one of the top horror podcasts according to Rue Morgue Magazine, blumhouse.com and Entertainment Weekly! Join hosts; Johnny Wolfenstein, MonsterZero, Ares, and Michael Ravenshadow as they discuss all manner of topics including, but not limited to: genre cinema with a heavy focus on horror and recent VOD, music, comics, video games, professional wrestling, and anything else relevant to the interests of the hosts. The show is broadcast via live video stream every Thursday evening from 8-11pm EST and can be viewed at live.trickortreatradio.com. The audio gets released every Friday morning on Apple Podcasts, Spotify, Stitcher, etc. Come check out the world's most dangerous talk radio show! *This podcast is explicit and not recommended for the faint of heart!	https://storage.buzzsprout.com/variants/tieybgCW4Kr4TqsKpjuMzxew/8d66eb17bb7d02ca4856ab443a78f2148cafbb129f58a3c81282007c6fe24ff2?.jpg
2782	http://fpmplay.podbean.com/feed/	FPM Play	Jacob and Andres Echevarria	FPM Play is a pop culture podcast for kids and parents. Jacob and his dad along with rotating co-hosts talk about TV, Movies, Video Games, Books and more.  We encourage every parent to have active an conversation with their kids about the media they are consuming and exposed to on a daily basis.	https://pbcdn1.podbean.com/imglogo/image-logo/476845/FPMPlayPodcastCover.jpg
2787	http://promodj.com/RomaPafos/podcast.xml	Roma Pafos	PromoDJ (hyperder@mail.ru)	Рома Пафос: Основатель Mediadrive records, Mediadrive labels group, Продюсер, Диджей \n Рома Пафос - имя, которое привлекает, располагает, раздражает, но никогда не оставляет равнодушным. Никогда и никого. Талантливых и увлеченных он ведет за собой. Команда лейбла Mediadrive Records – это единомышленники, гении и будущие звезды. Качественное звучание, отличающее работы резидентов лейбла – это не миф. Это его стремление к перфекционизму. Как говорит Рома Пафос:...	https://cdn.promodj.com/afs/9a5f72a26667ec55e5a5e9698f139455:resize:1400x1400:same:a4ef89.png
2790	http://sbctampa.podomatic.com/rss2.xml	Southside Baptist Church, Tampa FL	Southside Baptist Church	Southside Baptist Church\nPastor Kerry Nance\n3911 W. Bay Ave\nTampa, Florida 33616\n813-837-3334\nwww.sbctampa.org\nwww.facebook.com/sbctampa	https://assets.podomatic.net/ts/25/b7/22/webadmin91958/1400x1400_8277631.jpg
2793	http://feeds.feedburner.com/DjOguia-DeepReleaseEp01OnVibesRadioMarch2012	DJ oGuia - Deep Release ep. 01 on Vibes Radio March 2012	DJ oGuia (noreply@blogger.com)	Deep Release ep. 1 radio show on Vibes Radio Station 18th March	http://ia700807.us.archive.org/25/items/DjOguia-DeepReleaseEp.01OnVibesRadioMarch2012-Cover/DeepReleaseByDjOguia-Cover1024x768.jpg
2794	http://www.blogtalkradio.com/abetterworld/podcast	A Better World with Mitchell Rabin	A Better World Radio	To get educated & inspired about many of the ways to build a better world for all.	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzLzVmYTFjMDM5LTkxMDEtNDE5ZS1hN2U4LWZjZjMyNzllMjkwNV9taXRjaGVsbC1yYWJpbi1ieS1mbG93ZXItYnVzaC5qcGc/5fa1c039-9101-419e-a7e8-fcf3279e2905_mitchell-rabin-by-flower-bush.jpg?mode=Basic
2795	http://feeds.feedburner.com/SunshineNews	Sunrise NEWS Podcast	Henry George Wolf VII	This will be a resource targeted for English students and teachers in Japan. It is intended to be supplemental reading material that is appropriate for the students' English level. The goal is to motivate students to enjoy English through current events. This is a weekly magazine, released each Sunday. At the moment there is one article for each level. It will continually evolve and expand.	http://sunrisenews.jp/Sunshine.jpg
2797	http://www.frenchetc.org/homecategory/mot_du_jour/feed/	Mot du jour Podcast – French Etc	anne@frenchetc.org (Mot du jour Podcast – French Etc)	Our Mot du Jour Podcast helps you become au courant with short 21st-century French words and expressions in context.<br />\nTired of textbook French? All our Podcasts teach you real French, the way it’s spoken on the streets of Paris and in the cafes in Nice, with authentic useful expressions you can use right away.<br />\nMot du Jour Podcast is published 5 times a week.	https://www.frenchetc.org/wp-content/fichiers/logos/frenchetclogov3_144.png
2799	http://multnomah.granicus.com/VPodcast.php?view_id=2	Multnomah County, OR: New View Video Podcast	Multnomah County, OR		http://admin-101.granicus.com/content/multnomah/images/multnomah_audio_PODCASTS.jpg
2800	http://podcast.ulcc.ac.uk/accounts/kings/Philosophy_podcasts.xml	History of Philosophy Without Any Gaps	Peter Adamson	Peter Adamson, Professor of Philosophy at the LMU in Munich and at King\\'s College London, takes listeners through the history of philosophy, \\"without any gaps.\\" The series looks at the ideas, lives and historical context of the major philosophers as well as the lesser-known figures of the tradition. www.historyofphilosophy.net	https://pbcdn1.podbean.com/imglogo/image-logo/697911/HistoryofPhilosophy-1400.jpg
2801	http://www.blogtalkradio.com/googlemetalkradio.rss	Google Me Talk Radio | Host  Jim Cobb	Archive	Google Me Talk Radio is provoking commentary on today's society and how technology and the internet has and will transformed our business lives. Entrepreneurs, Network Marketers, Home Based Business, Multi-Level Marketers and Online Business Owners.  Call in NOW!!  It's all about you and your business.	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/fe864192f160be765fcbfe0ecc4a2780.jpg
2802	http://www.coge.org/rss/podcast.php?langue=italiano	CoGe.oRg Podcast - Edizione italiana	CoGe.oRg	Podcast delle registrazioni dei Cori e Orchestre delle Grandes Ecoles, Parigi, Francia. Prima formazione musicale degli studenti di Parigi, il COGE, da oltre 20 anni, riunisce ogni anno nell'ambito dei suoi cori e orchestre più di 300 studenti provenienti dalle Grandes Ecoles e università di Parigi e la sua regione, attorno ad una passione comune: la musica.\n\nPiù informazioni disponibili nel sito internet storico https://www.coge.org/	https://www.coge.org/img/podcast/logo-ita.jpg
2803	http://feeds.feedburner.com/McmillinRacing	McMillin Racing	Bob Yen	McMillin Racing/SCORE CORR BITD/Offroad Racing program	http://www.jumplive.com/itunes/dmcmillin.png
2810	http://gemz.podOmatic.com/rss2.xml	Gemma Furbank's Podcast	Gemma Furbank	•PLEASE VOTE FOR GEMMA ON THE DJ LIST - THANK YOU  \n\n \nhttp://thedjlist.com/djs/GEMMA_FURBANK/\n\n• OFFICIAL VESTAX EUROPE PRO ARTIST alongside Carl Cox, PVD, Jeff Mills, Grooverider & more. \n• FOR TECHNO: SIGNED TO WWW.UNIONLABEL.IT alongside Alex Di Stefano, Alex D'Elia, Norbert Davenport, Nihil Young, Loco & Jam,Phuture Traxx, Citizen Kain, Worakls, D-Unity,Miniminds,Antoni Bios,Dualitik & more\n• TECHNO NORTH AMERICA: WWW.RE-KONSTRUKT.COM alongside Sasha Carassi, Alex Bau, Sam Paganini, Gayle San, Loco & Jam, Sutter Cane, Spektre, DJ Emerson, Tomy DeClerque Angel Costa, Tom Hades, Phunk Investigation, Dandi & Ugo, GoIDiva, A-Brothers, Mike Väth, Frank Sonic, Nihil Young, Hugo Paixao, Andres Gil, Hackler & Kuch, Submerge, Ricardo Garduno, Repressor, Erphun, Measure Divide, Yan Cook.\n\n✪ BOOKING:\n• TECHNO WORLDWIDE : anna@unionlabel.it \n• MEXICO email: Hipnotik_productions@hotmail.com\n• NORTH AMERICA: www.re-konstrukt.com/#!bookings/c61v\n• DEEP HOUSE/ELECTRONICA/TECH email: Rob at gemmafurbank.bookings@gmail.com\n\n\nGemma Furbank is a hot Techno & House music rising star! As a DJ, she is well-known for bringing truly sublime tracks together with flawless precision... \n\nInspired by a whole range of Artist's from her many year's of being an avid club dweller, but in particular - Paul Oakenfold where it all started for Gemma, and currently James Zabiela and his mind blowing technique.\n\n\n•August 2009 ESSTIGE DJ OF THE MONTH\n•January 2010 MANCHESTER’S BEST DJ finalist (as chosen for by online vote's)\n•August 2011 Gemma’s Ranking on www.thedjlist.com rocketed seeing her placed at No.139 In The World’s Best DJ’s No.4 Female DJ, becoming the UK’s No.1 female DJ sitting at No.22 overall in the UK’s Best DJ’s, No.1 Female Techno DJ in the world and No.20 overall in the World’s Best Techno DJ’s and again in The World’s Best House DJ’s ranked as No.1 Female and Number 46 overall.\n•September 2010 - Gemma is signed to www.unionlabel.it - a wicked techno label joining Alex D'Elia,Nihil Young,Norbert Davenport,Alex Di Stefano,Loco & Jam,Phuture Traxx, Citizen Kain, Worakls, D-Unity,Miniminds,Antoni Bios,Dualitik and more - a label that partner's Binary 404, Ready 2 Rock, Frequenza, CODE,Voodoo Records,Blending Rival Records and more.\n•January 2012 - VESTAX EUROPE - Test driving the amazing new, top of the range VCI-400 Software Controller!\n•January 2012 - SWISS SOUNDSYSTEM ARTISTS' ROSTA 2012 - With some of the Industries leading Artists and DJs!\n\n\n\n•GIG’S/INTERNATIONAL TOUR’S:\n\n2009 saw a meteoric rise to the forefront of the Manchester and UK scene for Gemma. Regularly clocking up high profile gig’s throughout the UK, including regular slot’s at the DJ Mag’s World No.1 club SANKEYS, and it’s sister club SPEKTRUM, gig's at GOODGREEF 53 Degrees Preston , GOODGREEF Sankeys Mcr, HOUSEJUNKI & SCREWBALL Mcr, THE VENUE Dumfries, UBER Carlisle, TRUTH Preston, VERTU Birmingham, AVICI WHITE Mcr, LABEL Mcr, AREA 51 Mcr, PLUSH Mcr, FULL MOON PROMOTIONS Boat parties Mcr, LE CLUB Long Eaton, also playing UK Festival’s including REVIVAL SUMMER SOUNDSYSTEM Blackburn, RAVENTSTONEDALE Cumbria, MOZFEST Lancs, with many other gig’s beside’s. Gig’s from all over the world have been flowing nicely, Gemma is taking the International Circuit by storm! Seeing in the year 2010, headlining in Pune, India. With bookings for Bahrain, Egypt and Lebanon, and headlining the world’s biggest brand MINISTRY OF SOUND’s world tour’s, including Hurghada Egypt, tour’s of India, Dubai, Montpelier, Mauritius and France. Gemma made her Irish debut at one of Europe’s biggest festival’s in 2010. OXEGEN FESTIVAL, an event that attract’s over 90,000 reveller’s daily, being interviewed for IMTV - with her co-produced track "Sub-Sonic" opening up the festival! December 2011, saw Gemma make her long awaited German debut, something that Gemma had always wanted to do being a Techno dj - it's safe to say she definitely put her stamp on thing's and Germa(continued)	https://gemz.podomatic.com/images/default/podcast-4-1400.png
2811	http://tkyourdj.weebly.com/uploads/1/4/3/9/14391132/kirkpatrick_podcast_rss.xml	Kirkpatrick Podcast	Matthew Kirkpatrick	Matthew Kirkpatrick and TK Your DJ.	https://sphotos-b.xx.fbcdn.net/hphotos-ash3/534174_371305102945737_720457566_n.jpg
2812	http://showemjesus.com/?feed=podcast	Show ’em Jesus	Mark Simpson	Bible teaching by Mark Simpson in which the ancient text of Scripture is examined and applied to our postmodern culture for the purpose of inspiring a passion to know and imitate Jesus Christ.	http://www.showemjesus.com/podcast/podcast%20logo.png
2813	http://tm-bimyou.seesaa.net/index20.rdf	たみちゃん、まおちゃん微妙な関係	たみちゃん＆まおちゃん	たみちゃんこと坂野多美と大魔王ラジオチャンネルのまおちゃんこと大魔王が とにかく微妙な関係のままスタートさせてしまったネットラジオ 果たして2人は微妙な関係から脱して仲良くなれるのか！？	http://tm-bimyou.up.seesaa.net/image/podcast_artwork.jpg
2814	http://feeds.feedburner.com/comicbooktesseract	Comic Book Tesseract	Justin Chaloupka, Jason Poleyeff	Comic Book Tesseract, the only comics netcast that’s bigger on the inside than it is on the outside.  Join us as we review and preview the world of comics along with other facets of geek-chic culture.	http://4.bp.blogspot.com/-LD9zSBVKlm4/Tm69IZWyEaI/AAAAAAAAAAU/QdHLUvLCg9k/s1600/Comic-Book-Tesseract-.png
2815	http://www.blogtalkradio.com/jonathan-lansner.rss	Jonathan Lansner	Archive	Orange County Register columnist/blogger talks about Orange County, California's real estate!	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/5339f07a2f840f4b562e281cfc868609.jpg
2817	http://feeds.feedburner.com/ShortFilmOfTheWeek	Short Film of the Week	Anthony Dalesandro	A place to see the best short films on the web.	http://www.anthonydalesandro.com/SFotW_logo.jpg
2818	http://www.blogtalkradio.com/usatalkradio.rss	USA Talk Radio	USA Talk Radio	Current Events, Variety, and More...	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzL2IwNTJkN2E3LTk2MmYtNDI0NC04MTk2LTc1ODAxYzhiYTEyOF9pY29uLmpwZw/b052d7a7-962f-4244-8196-75801c8ba128_icon.jpg?mode=Basic
2821	http://www.blogtalkradio.com/goldandblackcom.rss	Gold and Black Radio	Gold and Black Radio	The staff of GoldandBlack.com breaks down the latest in Purdue sports news.	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzLzlhMDExYjRjLWE0NzMtNDFlYy1iMDc4LTcyY2NkYWM5Y2YyOV9yYWRpb2xvZ28uanBn/9a011b4c-a473-41ec-b078-72ccdac9cf29_radiologo.jpg?mode=Basic
2823	http://feeds.feedburner.com/podcasts/NeilCavutosCommonSense	Neil Cavuto	Fox News Channel	From Main Street to Wall Street, Common Sense is more than just facts and figures. Neil gets to the heart of what matters to you	http://public.media.foxnews.com/PODCASTS/fn-itunes-podcasts-thumbnails-common-sense.jpg
2824	http://www.blogtalkradio.com/kickingsystem.rss	KickingSystem	Archive	The Kicking System, based in San Diego, CA, is the authority on all things kicking. Get informed and improve your kicking by joining former NFL, NCAA, and Arena League Kickers, John Matich and Tim Valencia.  Resources include interviews, technique guidance, workouts, recruiting and much more. Interviews have included : 2010 Pro Bowl Kicker, Billy Cundiff,2010 UFL Kicker of the Year, Nick Novak and 2010 Arena League Kicker of the year, Chris Gould. <br /><br />Loaded with kicking information!	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/1110509e462e1cdd2faae957e525be29.jpg
2825	http://feeds.feedburner.com/GamingKaffet	Gaming till Kaffet	Magnus & Kristoffer	Svensk spelpodcast med sällan skådad fräschör i såväl språkbruk som åsikter.	http://www.gamingtillkaffet.se/bilder/itunesbild.jpg
2827	http://feeds.feedburner.com/Breathingplanet	My Survival Kit	breathingplanet (noreply@blogger.com)	www.breathingplanet.net	\N
2829	http://feeds.feedburner.com/TheRizzoliAndIslesPodcast	The Rizzoli and Isles Podcast	The Rizzoli and Isles Podcast (noreply@blogger.com)	Amanda and Jay, best friends, discussing their favorite hit TV show Rizzoli and Isles.	http://i11.photobucket.com/albums/a184/dacharmedone/podcico.jpeg
2830	http://feeds.feedburner.com/webmarketing24	Strategia Digitale	YouMediaWeb	Idee, novità e consigli per imprenditori e professionisti appassionati di Web Marketing e Business Online. A cura di Giulio Gaudiano.<br /><br />Entra nella community su <a href="http://strategiadigitale.info" rel="noopener">http://strategiadigitale.info</a>	http://d1bm3dmew779uf.cloudfront.net/big/7510acb5203991f0631b73f896f629aa.jpg
2831	http://www.radiovaticana.va/rss/italiano105.xml	Radio Vaticana - 105 Live	webteam@vaticanradio.org	One O Five Live - La Radio Vaticana in diretta	http://www.radiovaticana.va/RSS/logo_pod_news_105.jpg
2833	http://emsgarage.com/?feed=podcast	EMS Garage	chris.montera@gmail.com (EMS Garage)	EMS Garage is a weekly podcast with industry insiders discussing the important topics of EMS and Paramedicine.	http://www.emsgarage.com/wp-content/uploads/2019/03/EMSGarage.jpg
2834	http://feeds.feedburner.com/its	INTERVIEW	プロインタビュアー 早川洋平 (inquiry@kiqmaga.com)	「人の話には、人生を変える気づきがある」。\r\n\r\nキクマガは、各業界で活躍されているゲストスピーカーの皆さんから、「人生を変えるきっかけ」をうかがうインタビューマガジンです。\r\n\r\n人生のターニングポイントとなった出来事・モノ・人から、日々大切にしている習慣や考え方などについて、毎月、あなたの明日に響くインタビューをお届けします。\r\n\r\n【ご登場いただいたゲストの方々】\r\n加藤登紀子さん（歌手）、鳥越俊太郎さん（ニュースの職人）、石田衣良さん（作家）、渡邊美樹さん（ワタミ会長）、茂木健一郎さん（脳科学者）、小出裕章さん（京大原子炉実験所助教）、松浦弥太郎さん（『暮しの手帖』編集長）、龍村仁さん（『ガイアシンフォニー』監督）、高野登さん（人とホスピタリティ研究所代表）、本田健さん（作家）、神田昌典さん（経営コンサルタント）、和田裕美さん（人材育成会社代表）、アラン・コーエンさん（作家）、柳澤大輔さん（面白法人カヤック代表）ら、134人がご出演くださいました（2013年3月2日現在）\r\n\r\n※これまでに配信した全インタビューは、ウェブサイト〈kiqmaga.com〉から無料でお聴きいただけます。	http://podcast.kiqtas.jp/jinsei1-is/images/logo_interview.png
2835	http://www.screencast.com/users/SJBarry/folders/MHS+AP+Chemistry/itunes	MHS AP Chemistry	Scott J. Barry		\N
2839	http://feeds.feedburner.com/soundcloud/nAMd	Cox n' Crendor Show	Cox n' Crendor Show	The highest quality non-content 30 minute morning show on the internet in podcast form. Hosted by Jesse Cox and Eric "Crendor" Hraab. Featuring daily news, sports, weather, and commentary.	http://i1.sndcdn.com/avatars-000393084681-9261um-original.jpg
2840	http://lovelongandprosper.com/podcast/feed/	Comments on:	\N	A Star Trek Podcast	\N
2843	http://feeds.feedburner.com/NegativKontaktsokning	Negativ Kontaktsökning	Elin & Johanna	En podcast med, om och för dårar och andra genier.	http://negativkontaktsokning.files.wordpress.com/2013/01/podbild2.jpg
2845	http://geekfights.podbean.com/feed/	Geek Fights	Geek Fights	At Geek Fights we debate, discuss, deconstruct and deliberate the eternal burning questions of geekdom.	https://pbcdn1.podbean.com/imglogo/image-logo/266490/geek_fights_logo_1400x1400.jpg
2846	http://waynesboro.netadvent.org/podcasts/94.rss	Waynesboro (Va.) Seventh-day Adventist Church		Each Sabbath we are blessed by the message presented from God's Holy Word--a message that teaches us how to live reflecting the hope and grace that His love offers.  Welcome to our church, in person, or by podcast.	\N
2847	http://feeds.feedburner.com/IdiotsThink	idiot's think	idiots@idiotsthink.com	Our goal is be as truthful as possible even if we come off as morons. We sometimes have topics or sometimes we go on rants about stuff that is going on. We are both comedians who admit to our idiocy. We try to be funny while being truthful.	http://farm9.staticflickr.com/8196/8123941031_2ba87d5f70.jpg
2848	http://feeds.podtrac.com/3Edt4bkiM9c$	Trinity of Life (audio)	contact@yogahub.com (YHTV | YogaHub.TV)	We invite you to join our host, Christina Souza Ma as she ventures into the world of Yoga, Meditation, and Healing Arts. The diverse modalities that could support each of us in our journey through life, whether it is for yourself or a loved one that you are supporting. This program brings awareness for children through to Elders. What do you need at this time in your life? What does it take to find balance in your life’s journey? Come join us on Wednesdays at 11am PT (2pm ET). http://YogaHub.TV	http://tv.yogahub.org/files/powerpress/YHTV-TOL_1400x1400aud.png
2849	http://www.ivoox.com/feed_fg_f145017_filtro_1.xml	Fire Element Sessions Podcast By DJorge Caballero	DJorge Caballero	Fire Element Sessions Mixed by Andherson All The Best & New in Trance Music, Every 2 Weeks. Genre: Trance, Progressive, Techno.\n\nGenre: Trance, Progressive, Techno \n\nBio: \nJorge Alberto Caballero Diaz aka. DJorge Caballero, Andherson borned in Mexico, D.F. On July 24, 1990. \nSUPPORTED By PAUL OAKENFOLD, Manuel Le Saux, Many others artist Nowadays jorge possesses infinity of tracks produced and remixed, in which all the electronic styles such as electro, tech trance, tech house, etc. For him does not exist an specific genre.	https://static-2.ivoox.com/canales/3/3/1/3/9611470843133_XXL.jpg
2850	http://www.blogtalkradio.com/lumend13.rss	Pastor: Efraim Valverde Sr	Archive	Doctrina Fundamental: El Señor Nuestro Dios el Señor UNO es(Deut 6:4) Dios no es Trinidad(Juan 1:1, Col 1:15) El Nombre Supremo de Dios es Jesucristo el Señor(Fil 2:9) El Bautismo es por inmersion (Rom 6:4) en el Nombre de Jesucristo el Señor( Hch 2:38) la Iglesia del Señor no es una organizacion religiosa, es el Cuerpo de Cristo (1Cor 12:27, 2 Tim 2:19)...<br />Church of Jesus Christ in the America, <br />Temple Philadephia<br />160 Pajaro St<br />Salinas Ca 93901<br /><br /><a href="http://www.evalverde.com" rel="noopener">www.evalverde.com</a>	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/024ad53fdc20ad0e173981d755ce26fc.jpg
2851	http://www.radionz.co.nz/podcasts/countrylife.rss	RNZ: Country Life	RNZ	Country Life takes you down country roads to meet ordinary people achieving their dreams. We live in a beautiful country...	https://www.rnz.co.nz/assets/programmes/icons/13/1400_N_Country_Life1400x1400.jpg?1542341592
2852	http://www.buzzsprout.com/6423.rss	CfL podcast om ledelse	CfL	Podcast henvendt til danske topledere	https://storage.buzzsprout.com/variants/kqfp3mbyujbkvfds2976fqwhrjru/8d66eb17bb7d02ca4856ab443a78f2148cafbb129f58a3c81282007c6fe24ff2.jpg
2853	http://librivox.org/rss/5898	Pony Rider Boys in Texas, The by PATCHIN, Frank Gee	LibriVox	Yee-hawww! The Pony Rider Boys are on the trail again! In the second book of this series, Professor Zepplin has taken the young men to San Diego, Texas, to experience the life of a cowboy. The cattle drive will take them across the great state of Texas, where they will meet many dangers and adventures. (Summary by Ann Boulais) \n\nPrevious book in the series: The Pony Rider Boys in the Rockies\nNext book in the series:  The Pony Rider Boys in Montana	\N
2854	http://www.screencast.com/users/Lane_Crawford_BJ/folders/Lane+Crawford_Brand+Pronunciation_Menswear/itunes	Lane Crawford_Brand Pronunciation_Menswear	Lane Crawford Beijing	Brand pronunciation files for SS12 for Menswear department	\N
2855	http://feeds.feedburner.com/CSEprep	CSE Prep	David Doucette (david@cseprep.com)	This is the ONLY podcast dedicated to helping candidates prepare and pass the California Supplemental Exam.	https://californiasupplementalexam.com/wp-content/plugins/powerpress/rss_default.jpg
2856	https://www.perimeter.org/podcasts/perimeter_podcast.xml	Perimeter Church Podcast	Frances Hoyt	The Perimeter Church Podcast - Weekly Messages from Perimeter Church in Johns Creek, GA.	http://www.perimeter.org/podcasts/podcastlogo.png
2857	http://feeds.feedburner.com/MIRvideo	Mobile Industry Review Show (Large M4V)	Mobile Industry Review (ewan@mobileindustryreview.com)	This is the M4V (large-screen mobile video) feed for the Mobile Industry Review Show - ideal for viewing on a larger-screen mobile phone.	http://www.smstextnews.com/media/podcasts/MIR_300x300.jpg
2858	http://feeds.feedburner.com/animepodcastnet	AnimePodcast.net (あ!PoN)	animepodcast.net	This podcast covers anime-related interviews with industry people. Japanese directors, producers, and talent. Along with people who work in US anime industry.	http://creativecommons.org/images/public/somerights20.gif
2860	http://feeds2.feedburner.com/REEnglish	Reverse Engineering English | リバース・エンジニアリング・英語	Weblishメディア英会話 | John Daub	リバース・エンジニアリング・英語　\r\nこの番組ではまず日本語の例文を挙げ、それを単語ごとに切り離し、英語に翻訳します。そしてその英単語から英語の文章を作り、再び日本語の文章へと翻訳する方法を勉強します。\r\nこれが楽しみながら勉強になる英語を学べる「REVERSE ENGINEERING」です。ホストはジョン・ドーブ。質問やコメントがあるときにはWeblishジョン・ドーブまで連絡して下さい！お楽しみに～！\r\nThis podcast takes example sentences in Japanese, takes it apart, translates it into Englsh, makes an English sentence, then shows how to make the Japanese sentence again. This is REVERSE ENGINEERING for learning English, and it is fun and informative!  Host: John Daub  Please contact John at Weblish if you have any comments or questions.  Hope you enjoy the show!	http://weblish.net/images/REE_Bicon.jpg
2861	http://wlw2.podomatic.com/rss2.xml	Women Love Wrestling 2's Podcast	Women Love Wrestling 2	**** IMPORTANT NOTICE: Melanie and Corie. Our show has been moved to http://blogtalkradio.com/wlw2 \n\nSame day and time. Wednesdays 9:30PM EST. \n\nWe talk WWE, TNA, weekly shows like Smackdown & RAW. Plus PPV's. It's an opinion show with explicit language at times. Enjoy! \n\nFollow us on Twitter http://twitter.com/wlw_2	https://wlw2.podomatic.com/images/default/podcast-3-3000.png
2863	http://djtwisteddee.podomatic.com/rss2.xml	DJ Dee Martello (Twisted Dee)	Dee Martello (Twisted Dee)	DJ/Producer - Tribal & Progressive House Music! \n\nI may not have muscles and a d*ck, but I have more balls than most men I know ;-)~	https://assets.podomatic.net/ts/03/15/cc/djtwisteddee/pro/3000x3000_2883734.jpg
2864	http://patrick.fm/telefoon.xml	Gekke Telefoon Gesprekken	Patrick Kicken | Veronica	Gekke Telefoongesprekken uit de radioshows van Patrick Kicken bij Radio Veronica. Kijk voor meer op http://sndcld.nl	http://patrick.fm/telefoon.jpg
2865	http://feeds.feedburner.com/blogspot/bkztq	Silent Night	Will Taylor	Silent Night and many other carols for your holiday cheer	http://www.amandolinchristmas.com/uploads/3/5/4/6/3546135/2329743_orig.jpg
2866	http://feeds.feedburner.com/tumblr/BnRr	Dangerous:Memories	Hector and Todd	A podcast from two gentlemen who love movies and want to watch the AFI top 100. Feel free to visit our web site: www.hectorandtodd.com we would love to have you.	http://i16.photobucket.com/albums/b12/wesmantooth/DMposterART1b.jpg
2868	http://feeds.feedburner.com/GamePeopleNovelGamerPodcast	Game People's Novel Gamer Show	Paul Govan	I write stories to say what I think about games, for me it's the only way I can really communicate what I feel about them. Do you ever have a response to something that's hard to put into words? I find that sometimes I have something to express that can't be communicated by trying to explain how I feel, directly. Often when we criticise games, films or stories we focus on technical areas: control, visuals, atmosphere, pacing and characters. I find that my personal responses aren't always defined by the sum of a games parts and I don't believe yours are, either.	http://www.gamepeople.co.uk/novel_podcast.jpg
2869	http://feeds.feedburner.com/powergamer/podcast	PowerGamer	Powergamer.se	Du kanske är trött på att läsa om allt innehåll här på sidan? Då kan du ladda ner vår återkommande podcast, där vi bland annat pratar om de allra senaste nyheterna, går igenom videos och bilder, recensioner och förhandstittar med mera.	http://www.powergamer.se/podcast/pg_itunes.jpg
2871	http://feeds.feedburner.com/boagworldpodcast/	The Boagworld UX Show	Paul Boag	Boagworld is a podcast about digital strategy, service design and user experience. It offers practical advice, news, tools, review and interviews with leading figures in the web design community. Covering everything from usability and design to marketing and strategy, this show has something for everything. This award-winning podcast is the longest running web design podcast with over 380 episodes.	https://cdn.simplecast.com/images/ae88e41b-a26d-4404-8e81-f97bca80d60d/e9976441-eb54-4a81-8046-31ee8b21011f/3000x3000/1425231145artwork.jpg?aid=rss_feed
2872	http://feeds.feedburner.com/Crossroads/AudioMessages	Crossroads Church	Crossroads	Exploring whether or not God even exists? or committed to following Jesus? We present biblical truths and show how they apply to our everyday lives. And we have a lot of fun while doing it. Whatever your thoughts on church, whatever your beliefs about God, you are welcome here.\n\nFor the longer answer, check out http://crossroads.net.	http://www.crossroads.net/uploadedfiles/CR_podcast_audio.jpg
2874	http://www.blogtalkradio.com/rssfeed.aspx?user_url=worldfootprints	WORLD FOOTPRINTS	World Footprints	World Footprints allows listeners to experience travel in a deeper way and raises awareness about important global issues through interviews with leading celebr	https://dasg7xwmldix6.cloudfront.net/hostpics/retina/b9003fee-036c-431c-8085-3582e14e6b71_worldfootprints_5x5in_rgb.jpg
2877	http://norrteljetidning.podomatic.com/rss2.xml	Norrtelje Tidning's poddradio	Norrtelje Tidning	Med Lincoln City och Bookmakers.	https://assets.podomatic.net/ts/12/f7/43/22027/1400x1400_9481862.jpg
2879	http://feeds.feedburner.com/NSPodcastRAD	Nice Slice! Podcast	Ryan Andes, Andre Calderon, Darren Cotta	Three friends get together and discuss hot topics and make fun of any and everyone. No one is safe.	http://sphotos-a.xx.fbcdn.net/hphotos-snc7/600114_232949413501762_1705836922_n.jpg
2881	http://feeds2.feedburner.com/104HistoiresDeNouvelle-france	104 histoires de Nouvelle-France	courriel@jfblais.ca (Jean-Francois Blais)	Des capsules audio dans lesquelles je vous raconte l\\'histoire de personnages inconnus ou méconnus de la Nouvelle-France.	http://104histoires.com/episodes/104hst_onglet_2018_02.jpg
2883	http://librivox.org/rss/6802	New Colossus, The by LAZARUS, Emma	LibriVox	LibriVox volunteers bring you 26 recordings of The New Colossus by Emma Lazarus. This was the Fortnightly Poetry project for June 24, 2012.Lazarus wrote her own important poems and edited many adaptations of German poems, notably those of Johann Wolfgang von Goethe and Heinrich Heine. She also wrote a novel and two plays. Her most famous work is "The New Colossus", which is inscribed on the pedestal of the Statue of Liberty. Lazarus' close friend Rose Hawthorne Lathrop was inspired by "The New Colossus" to found the Dominican Sisters of Hawthorne. (Summary by Wikipedia)	\N
2887	http://feeds.feedburner.com/DoNBTS	Project: Shadow	Charlie Dorsett	We understand the world through stories we tell ourselves, those others tell us, and those that entertain us, seeing ourselves in them even when they don’t contain people like us.\n\nMy name is Charlie, and I write Scifi/fantasy as C. E. Dorsett. As a queer writer, I dive into the deep structure of the books, movies, and shows that we love, and would love to take you with me through our fandoms and the works I create. We will dive into these worlds to reveal unseen wonder, discuss theories, and contemplate the elements of good writing. If you have any questions or topics, share them with me. Support this podcast: <a href="https://anchor.fm/projectshadow/support" rel="payment">https://anchor.fm/projectshadow/support</a>	https://d3t3ozftmdmh3i.cloudfront.net/production/podcast_uploaded_nologo/802/802-1597011095586-900d48de89037.jpg
2889	http://feeds2.feedburner.com/cnet/howtohd	CNET How To (HD)	CNETTV (stephen.beacham@cbsi.com)	See all the steps for solving tech problems or just getting more out of What you're using. Whether it's a computer tip, tweaks and tricks for your DVR, or ways to get more out of your smartphone, you'll find it in CNET How to. Each video is helpfully rated easy, medium, difficult or supergeek.	https://cnet4.cbsistatic.com/hub/i/2016/05/10/e5c04aaa-dc12-4794-9832-e098d925b35b/howtonew300x300.jpg
2891	http://www.domaine.info/squelettes/rss/podcast.php	Domaine.info Channel	Domaine	L'actualité techno	http://www.domaine.info/squelettes/nopicture.jpg
2892	http://www.sf-radio.net/syndication/feeds/sendungen/soundwords.xml	SF-Radio	\N	Listen to the Universe!	\N
2894	http://www.blogtalkradio.com/amdg.rss	The AMDG Radio Network	The AMDG Radio Network	Current Events | Pop Culture | Sport | Travel | The Permanent Things | Fully indexed site at www.amdgradio.com	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzLzE4NmMxNWJhLTg5YTUtNDA2Ni05MzAwLTk2N2U0NzUwZjUxYl9hbWRnX2xpbmtlZGluXzUwMHg1MDAuanBn/186c15ba-89a5-4066-9300-967e4750f51b_amdg_linkedin_500x500.jpg?mode=Basic
2895	http://mrphipson.podspot.de/rss	Mr Phipson | urban musique for urban souls	Mr Phipson	Sportive Baile Funked up jazzy audio joints. Berlin based Mr Phipson presents you an urban mixture of tunes from the past and future. Bossa Nova, Jazzed Up Beats, Electronica, Tropicalectro, Brazilian Beats, Tropicalia, Rare Grooves, Afro-Latinized Funk, Drums'n Breaks, Drum'n Bossa, Deep Beats, Baile Funk, Hippy Hoppy and other funky oddities. From the good old times back in the days to the era of dual processor powered favela funk. The sound of shantytowns worldwide from underground to Roots Jazz and all the good things inbetween. Stay open minded, discover krazee urban soundtracks and tune in to Mr Phipson's incredible Podcast!	\N
2899	http://feeds.feedburner.com/smartem	Comments on:	David H Newman	SMART EM is a medical podcast dedicated to evidence. If  evidence is out there on a monthly topic, we'll find it and bring it to you, then you decide. No more accepting what you're told—it's time to hear about the data.	http://smartem.org/sites/default/files/images/SMARTEM_iTunes_icon_0.jpg
2901	http://www.blogtalkradio.com/hustlegrindradio.rss	J_Milly	Archive	JOIN YA GIRL JMILLY FOR "HUSTLE & GRIND RADIO" LIVE BRINGING YOU THE BEST INTERVIEWS & MUSIC FROM THE TOP PROMOTERS, MANAGERS, A&amp;R'S, SIGNED, UNSIGNED & INDIE HIP HOP & R&amp;B...KEEP IT LOCKED TO HEAR HOW THE TOP MEN & WOMAN OF THE INDUSTRY HAVE BECOME SUCCESSFUL!  IT'S MY GOAL TO EMPHASIZE ON THE BUSINESS SIDE OF THE INDUSTRY. I AM DEVOTED TO GIVING ANYONE IN THE INDUSTRY AN OPPORTUNITY TO BE SEEN AND HEARD! <a href="mailto:jmillyinterviews@gmail.com">jmillyinterviews@gmail.com</a>	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/b6c88a4d5e6553dc30b62dbeaf27b650.jpg
2904	http://whatswright.podOmatic.com/rss2.xml	What's Wright with Nick Wright	Nick Wright	My daily radio show.  It's a combination of sports, hip hop and (a little) politics.	https://whatswright.podomatic.com/images/default/podcast-1-1400.png
2905	http://feeds.feedburner.com/savepointcast	obat kurap tradisional	obat kadas kurap (noreply@blogger.com)		\N
2908	http://www.blogtalkradio.com/draftdaydk.rss	Draftday.dk	Archive	Draftday.dk - Football For Folket! Ugentlige podcast om amerikansk football, NFL, college football og NFL draft.	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/192050c129a566461868aada1734d93c.jpg
2909	http://www.abc.net.au/gardening/video/gardening_mp4.xml	Gardening Australia	ABC Radio	Presented by Australia's leading horticultural experts and hosted by Costa Georgiadis, Gardening Australia is a valuable resource to all gardeners.	http://www.abc.net.au/cm/rimage/9518472-1x1-large.jpg?v=2
2910	http://feeds.feedburner.com/bina007	Bina007 Movie Reviews	Bina007	Ten minute reviews of arthouse movies and mainstream releases, as covered in depth at www.bina007.com	http://3.bp.blogspot.com/-Yd21sqKC0es/UdlbMN0iX3I/AAAAAAAACd0/1kxH1t0yLPI/s1600/blog.jpg
2911	http://www.discotronic.net/wordpress/discotronic_podcast.xml	DISCOTRONIC PODCAST	DISCOTRONIC	Discotronic Collective are a small group of international Djs, producers and VJ\\'s that know how to party-harty, mix to perfection and throw crazy events.	http://www.discotronic.net/wordpress/1_images/podcasts/discotronic_podcast_300px.jpg
2912	http://feeds.feedburner.com/obicomics	ObiComics	Serial Dad (didier.rols@gmail.com)	Partagez vos hobbies avec vos enfants ! Rappelez vous ces moments de pur bonheur que (j'espère) vous avez vous même vécu avec votre père ou votre mère ! Quoi de plus ludique et réaliste qu'une BD-photo pour ensemble, préparer un bon plat, fabriquer une piñata, dessiner le dernier concept-car de Citroën, monter un meuble IKEA ou comprendre la règle d'un jeu mal traduite de l'allemand...	http://idisk.me.com/irols/Public/Podcasts/ObiComics/logoobicomics.jpg
2914	http://feeds.feedburner.com/ec-m-podcast	EC-M-Podcast	EC-M / Stefan Erbe	In kurzen Episoden informieren wir Sie regelmäßig über Veranstaltungen des EC-M und über interessante Themen rund um den elektronischen Geschäftsverkehr.	http://ec-m.s-audio.de/podcast/EC-M-Podcast-Logo.png
2917	http://www.blogtalkradio.com/animal.rss	The Recruiting Animal	Recruiting Animal	There's no business show like The Recruiting Animal Show	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzL2RkMjZhNDJiLTA2NjQtNDYzNi1hODE0LWRkOGIwOWU4MjRjY3JlY3J1aXRpbmclMjBhbmltYWwlMjAzMDB4MzAwLmpwZw/dd26a42b-0664-4636-a814-dd8b09e824ccrecruiting_animal_300x300.jpg?mode=Basic
2918	http://artsedge.kennedy-center.org/podcasts/JazzDC.xml	Jazz in DC	ARTSEDGE: The Kennedy Center's Arts Education Network	From Fairmont Street to U Street, from the Howard Theater to the Crystal Caverns, take a tour through Washington, DC's jazz history with Billy Taylor and Frank Wess, who lead listeners through their hometown in this 6-part audio series created for middle and high school audiences.	http://artsedge.kennedy-center.org/podcasts/images/podcastCover_JazzDC.jpg
2919	http://feeds.drivingsports.com/dstv-extra	Driving Sports TV (Official Podcast)	Driving Sports TV	Driving Sports TV is the online video network featuring exclusive shows, news and automotive adventures!	https://pbcdn1.podbean.com/imglogo/image-logo/875366/itunes_dstv.jpg
2921	https://www.thieme-connect.de/rss/podcasts/10.1055-s-00000159.xml	Radiopraxis	Thieme Verlagsgruppe	Herzlich willkommen bei der Radiopraxis, der Fortbildungszeitschrift des Georg Thieme Verlags für MTRA und RT. Zu jeder Ausgabe von Radiopraxis erscheint ein Podcast, der auf einem aktuellen Heftbeitrag basiert. Die Podcasts können gratis abonniert werden. Der vollständige Heftbeitrag kann als PDF-Datei unter https://www.thieme-connect.de/ejournals/toc/radiopraxis erworben werden. In der Radiopraxis finden Sie praxisnahe Fortbildungsartikel mit Themen für das gesamte radiologische Team: Aktuell wie eine medizinische Fachzeitschrift, didaktisch ausgearbeitet wie ein Thieme-Lehrbuch. Sind Sie an einem Abonnement der Printausgabe von Radiopraxis interessiert? Ein Online-Bestellformular finden Sie unter https://www.thieme.de/fz/abo/radiopraxis.html. Radiopraxis - Die neue Art der Weiterbildung!	http://www.thieme-connect.com/rss/images/PodcastRadiopraxis.png
2922	http://www.catradio.cat/podcast/xml/8/1/podprograma1218.xml	El club de la mitjanit	Catalunya Ràdio	Xavi Campos presenta i dirigeix cada diumenge, a les 23 h, una tertúlia esportiva que no et deixarà indiferent	https://statics.ccma.cat/multimedia/jpg/8/2/1599490795228.jpg
2923	http://stationcaster.com/stations/knbr/rss/?c=11571	Giants Podcasts - KNBR	KNBR	KNBR is your home for everything Giants! Get all of our latest audio and interviews and take them with you where ever you go. KNBR is Giants baseball!	http://cdn.stationcaster.com/stations/knbr/media/jpeg/Giants_Podcasts.jpg
2924	http://www.waltinpa.com/feed/stbpodcastaudio/	Shooting The Breeze Podcast (Audio Only)	walt@waltinpa.com (Walt White)	This is the formal Gun Podcast from www.WaltInPA.com entitled "Shooting The Breeze". Episodes vary in length and cover Firearm News, Featured Content from around the Web, and a Featured Topic to close out the blog. This podcast also featured a Cigar and Beverage pairing to mix things up a bit.	http://www.waltinpa.com/images/Walt-Square.png
2925	http://emilykathleencooke.libsyn.com/rss	Emily Kathleen Cooke	Emily Kathleen Cooke	November 4, 1971\nJennifer Rose Cooke, a girl from California, just turned 18, goes missing in a frigid forest in West Germany. She has been hitchhiking. First she caught a ride with a trucker, then with a West German soldier. Maybe she was trying to visit a young professor she had met on the boat over from New York. On that trip, he had heard her say she might throw herself overboard.\nApril 28, 1972\nAnother girl, just turned three, lives with her parents in a house in Laurel Canyon that lets the California rain in. Her biggest fear is of the brown snails in the garden; she will not cross the brick path if one is there. It is her father's twenty-sixth birthday; on this day his sister Jenny's remains are found. Officially, she died of exposure, although a murder investigation is begun and the file remains permanently open.	https://ssl-static.libsyn.com/p/assets/0/a/9/1/0a91e44e58d9ddd0/NPCoverArt300x300.jpg
2926	http://nigozeroichi.podomatic.com/rss2.xml	SD Rocker No. 2501	Aaron C. L.	I wanted to start an on-line playlist that I could play at work through RSS Channel on PSP. Since I like mostly rock(and some foreign shit), that's pretty much what you're gonna listen to.	https://assets.podomatic.net/ts/bb/90/dd/nigozeroichi/3000x3000_996071.gif
2927	http://feeds.feedburner.com/acim	A Course In Miracles International	www.acimi.com	Nothing real can be threatened. Nothing unreal exists. Herein lies the peace of God.	http://www.acimi.com/catalog/images/Page_29C.jpg
2928	http://belforti.libsyn.com/rss	LeftRightandCorrect.com with Dan Belforti & Friends	Dan Belforti	Dan Belforti's libertarian talk show, broadcast weekly from Portsmouth, New Hampshire.	https://ssl-static.libsyn.com/p/assets/4/4/9/a/449ab89e71b62d2a/Senator_Clinton__Dan_Belforti_Feb_16_2005.jpg
2992	http://www.eston-studio.de/rssfeed/estonjournal.xml	ESTONjournal	erwin-spielvogel@t-online.de	Das ESTONjournal ist eine toenende Illustrierte als Podcast aus dem ESTON-Studio. Sie hoeren hier eine bunte Mischung unterschiedlichster Wort- und Musikbeitraege. Das ESTONjournal dient keinen kommerziellen Zielen und ist vollkommen unabhaengig. Mehr Informationen finden Sie unter www.eston-studio.de	http://www.eston-studio.de/rssfeed/Feedpic2.jpg
2929	http://djzx.podomatic.com/rss2.xml	DJ ZX's Deep Soulful, Gospel and Smooth Jazz Podcast	DJ-ZX	I am here to bring you a hot mix that I hope you like and will support. I do what I do for the love of music and I am now adding Smooth Jazz mixes to my love for music....so Thank you and Blessings!!!!!\n"My Soul Runs Deep In My House"\n\nMUSIC DISCLAIMER: This Music is made for entertainment purposes only and you can download these song on any authorized website such as, Traxsource, iTunes, Amazon.com, etc. No copyright infringement is intended in the making of this mix. In fact, I purchased these songs [Not a free download] but from the artist and or label for promotional use only. The music used remains the property of the respectful copyright owners.\nBuy "Remember Our Promise"\n\nPRIVACY NOTICE: Warning - any person and/or institution and/or Agent and/or Agency of any governmental structure including but not limited to the United States Federal Government also using or monitoring/using this website or any of its associated websites, you do NOT have my permission to utilize any of my profile information nor any of the content contained herein including, but not limited to my photos, and/or the comments made about my photos or any other "picture" art posted on my profile.\n\nYou are hereby notified that you are strictly prohibited from disclosing, copying, distributing, disseminating, or taking any other action against me with regard to this profile and the contents herein. The foregoing prohibitions also apply to your employee , agent , student or any personnel under your direction or control.\n\nThe contents of this profile are private and legally privileged and confidential information, and the violation of my personal privacy is punishable by law. UCC 1-103 1-308 ALL RIGHTS RESERVED WITHOUT PREJUDICE	https://assets.podomatic.net/ts/f7/d6/ab/djzx/3000x3000_9817329.jpg
2931	http://life2.podspot.de/rss	Life2-Podcast	Kirsten Erlenbruch	In unserem Life2-Podcast informieren wir Sie über Methoden wie z.B. Mentaltraining, die Sie bei der Verwirklichung Ihrer Erfolgspläne o. Ihre persönliche Weiterentwicklung nachhaltig unterstützen können.	\N
2932	http://feeds.feedburner.com/LandOfTheCreeps	Land Of The Creeps	Land Of The Creeps	Land Of The Creeps is a bi-weekly horror podcast show dedicated to reviewing horror movies in a fun yet informative way. With participation from the listeners and online calls. You are guaranteed to have a great time. GregaMortis Host,Co-Host Haddonfield Hatchet and Dr. Shock.	https://funkyimg.com/i/2WvEW.jpg
2937	http://feeds.soundcloud.com/users/2762800-kopoint/tracks	TheNews.fm	The News Team	TheNews.fm: The podcast about headlines & stories…	http://i1.sndcdn.com/avatars-000175067987-bfcs81-original.jpg
2938	http://downloads.bbc.co.uk/podcasts/radio3/jazzlibam/rss.xml	Jazz Library	BBC	Programme offering advice and guidance to those interested in building a library of jazz recordings or adding to an existing one	http://ichef.bbci.co.uk/images/ic/3000x3000/p03ntzrg.jpg
2940	http://www.buzzsprout.com/672.rss	Fellowship Bible Church - Topeka, KS	Fellowship Bible Church	Fellowship Bible Church is about helping people find and follow Jesus Christ. This podcast highlights the teaching from our weekend worship services. For more information about Fellowship Bible Church visit fbctopeka.com	https://storage.buzzsprout.com/variants/mj9ZtdgT4A6ttHMTpdQqAMjY/8d66eb17bb7d02ca4856ab443a78f2148cafbb129f58a3c81282007c6fe24ff2?.jpg
2943	http://www.br-online.de/podcast/katholische-morgenfeier/cast.xml	Katholische Morgenfeier	Bayerischer Rundfunk	Eine Stunde zum Atemholen, Nachdenken und Besinnen - das ist Bayern 1, Radio für Bayern, am Sonntag zwischen 10 und 11 Uhr. Die katholische und die evangelische Kirche haben dann das Wort. Pfarrerinnen, Pfarrer und Laientheologen beider Konfessionen gestalten die Bayern 1-Morgenfeiern.	https://img.br.de/852480a8-1d1f-434b-8110-8487151f4b06.jpeg?fm=jpg
2944	http://bmepodcast.libsyn.com/rss	Beta Male Experience Podcast		Beta Male Experience is a podcast by some 20-somethings about television, movies, music, and more.  We even have special guests and interviews.	https://ssl-static.libsyn.com/p/assets/d/6/8/1/d681c1f697b779a1/BME-Podcast-Art.png
2948	http://gamersuncut.podOmatic.com/rss2.xml	Gamers Uncut Podcast	Gamers Uncut	Wassup everybody!!! just wanna let yall know that this is the official page for the gamers uncut podcast. It's a gaming podcast (duh lol) that covers everything in the latest gaming news and provides the gaming community with an UNCUT perspective on video games and everything that happens in the gaming industry.....\n\nWe also talk about several life issues and whatever is on our mind in our UNCUT section of the podcast which is always towards the end of the show...\n\nYou can download the podcast on iTunes by searching Gamers Uncut....\n\nGamertag: Sik kid Pk\nPSN ID: Backpack92	https://assets.podomatic.net/ts/12/4f/c7/gamersuncut/1400x1400_2764663.jpg
2949	http://mollanfestival.podomatic.com/rss2.xml	Festivalpodden	Festivalpodden	Sveriges nästa nöjessajt Möllan.nu snackar festivaler och annat spex Festivalpodden.	https://mollanfestival.podomatic.com/images/default/podcast-3-3000.png
2951	http://essentialtennis.com/PodcastFiles/podcast.xml	Essential Tennis Podcast - Instruction, Lessons, Tips	Essential Tennis LLC	If you LOVE tennis, you badly want to improve, and you’re willing to work hard to achieve your goals then this is the tennis podcast you’ve been looking for! For over a decade tennis professional Ian Westermann has been answering questions for listeners all over the world with one goal in mind: making YOU a better tennis player. \n\nWhat topics are covered? Over the years no stone has been left unturned as Ian covers such topics as creating topspin, singles strategy, doubles strategy, mental toughness, stroke technique for the serve, forehand and backhand, fitness and conditioning, how to defeat pushers, mastery mindset and goal setting, how to change bad habits, footwork, defeating nerves during matches, tournament success, tie breaker success, breaking through plateaus, advice for tennis parents, and much, much more! \n\nDoes Ian’s audio tennis instruction translate into better on court results? In short, YES! \n\nThere’s a reason why the Essential Tennis Podcast is the highest rated tennis podcast in the world: Ian’s instruction actually does bring results. Tennis players all around the planet listen to his lessons thousands of times per day and are improving their tennis as a result. \n\nSo whether your technique needs polishing, your strategy is suffering, or your mental game is leaving you a wreck on the court this tennis podcast can take you to the next level. Start listening today so you can take full advantage of all Ian’s tennis knowledge! \n\nYou’ll also hear candid, in depth interviews with luminaries, book authors, and other experts in the game of tennis like Gigi Fernandez and Craig O’Shannessey. Ian loves spending time chatting with other podcast hosts as well in an effort to bring a well rounded, balanced approach to the thoughts and perspectives presented on his show. \n\nSubscribing to the Essential Tennis Podcast is hands down the best way to automatically get each episode that Ian publishes but you can also access each and every lesson at essentialtennis.com. From there you can manually download each .mp3 file into iTunes and listen to them on your computer or transfer them to your iPhone, iPod, or iPad to listen on the go.\n\nYou can also subscribe via the Podcasts App on your iPhone, the Play Music app on your Android phone, or through Spotify, Stitcher, or anywhere else you listen to podcasts. \n\nBe sure to check out all of the amazing video and written tennis lessons on www.essentialtennis.com as well. Everything at Essential Tennis is completely free and open to take advantage of. No matter what part of your game you need to improve you’ll find helpful instruction to get you to the next level. \n\nHave you enjoyed the Essential Tennis Podcast? Then please rate and review the show! It’s already the most highly rated tennis podcast on iTunes but Ian would greatly appreciate your support by leaving your comments and rating. \n\nThank you so much for listening and good luck with your tennis!	https://pbcdn1.podbean.com/imglogo/image-logo/2721732/New-ET-Logo-white-backdrop.png
2954	http://feeds.feedburner.com/DJCruzePodcast	Podcasts – DJ Cruze	DJ Cruze	Funky house music and dirty electro mixed live by DJ Cruze. Manchester is in the house!	http://www.djcruze.co.uk/cms/wp-content/djcruze_podcasts.jpg
2955	http://www.sermonindex.net/podcast_frombabylon.xml	SermonIndex.net Classics Podcast	Greg Gordon	The work and ministry of SermonIndex can be encapsulated in this one word: Revival. Concepts such as Holiness, Purity, Christ-Likeness, Self-Denial and Discipleship are hardly the goal of much modern preaching. Thus the main thrust of the speakers and articles on the website encourage us towards a reviving of these missing elements of Christianity	https://img.sermonindex.net/classics.jpg
2961	http://feeds.feedburner.com/publikai/podkasts	Podkāsti – ARHĪVS	Publikai	Alus Pučs	http://publikai.lv/publikai_rainbow.png
2962	http://www.radioformula.com.mx/podcast/janett.xml	La Mujer Actual	Radio Fórmula	Llegó el momento de superarnos, crecer juntos y alcanzar el bienestar integral, escuche a Janett Arceo, la Mujer Actual	http://www.radioformula.com.mx/images/programas/pod_janett_arceo.jpg
2963	http://site.afterbuzztv.com/cat_shows/ray-donovan-afterbuzz-tv-aftershow/feed/	The Ray Donovan Podcast	AfterBuzz TV	The Ray Donovan After Show breaks down episodes of Showtime's Ray Donovan.\n\nShow Summary: Ray Donovan is a "fixer" for Hollywood's elite. He is the go-to guy that the city's celebrities, athletes and business moguls call to make their problems disappear. It's a much more lucrative job than his previous work as a ruthless South Boston thug, vaulting him within reach of the truly wealthy and powerful. But no amount of money or the expensive things it can buy can completely mask Ray's past, a past that continues to haunt him with troubled brothers always calling and his father's recent release fr	https://d3t3ozftmdmh3i.cloudfront.net/production/podcast_uploaded_nologo/1050717/1050717-1537887949521-b22772107ceb2.jpg
2965	http://librivox.org/rss/5244	Old and New Masters by LYND, Robert	LibriVox	Jane Austen, WB Yeats, Chesterton, Shaw... these are personal and intelligent short essays on a selection of great (and great-ish) writers: some well known, and some a bit more obscure to the average reader today. Robert Lynd (1879 – 1949) is best known as a literary essayist and Irish nationalist. He published many essays, all written in an easy, conversational style. Lynd was an essayist after the manner of Charles Lamb, and deserves to be better known. A complete list of his works is available at Wikipedia: http://en.wikipedia.org/wiki/Robert_Wilson_Lynd (summary by chocmuse)	\N
2966	http://downloads.bbc.co.uk/podcasts/radio4/stw/rss.xml	Start the Week	BBC	Weekly discussion programme, setting the cultural agenda every Monday	http://ichef.bbci.co.uk/images/ic/3000x3000/p063j042.jpg
2967	http://www.jazzpianoteacher.co.uk/learn_jazz_piano.rss	Learn Jazz Piano	Paul Abrahams	The aim of these podcasts is to teach jazz and blues piano to keyboard players who already have some knowledge of their instrument but would like to improvise	http://www.jazzpianoteacher.co.uk/images/paul-phot0.jpg
2968	http://www.sermonaudio.com/rss_search.asp?keyword=IAN%25PAISLEY&keyworddesc=IAN+PAISLEY	Ian Paisley on SermonAudio	Ian Paisley	The latest podcast feed searching 'Ian Paisley' on SermonAudio.	https://www.sermonaudio.com/images/sermonaudio-new-combo2-1400.jpg
2971	http://lateralcutgroove.podOmatic.com/rss2.xml	Lateral Cut Groove Podcast	Lateral Cut Groove	Welcome to Lateral Cut Groove's podcast. Hear the best new electronic music from around the globe.	https://assets.podomatic.net/ts/65/8f/11/lateralcutgroove/3000x3000_7010582.jpg
2972	http://www.ozodi.org/podcast/?count=50&zoneId=557	Радиои Аврупои Озод/Радиои Озодӣ	Rferl.org	Радиои Аврупои Озод/ Радиои Озодӣ (РАО/РО) муассисаи мустақили амрикоист, ки тавассути Конгресси Иёлоти Муттаҳида таъмини молӣ мешавад. Барномаҳои РАО/РО, ки ба 28  забон дар ҳудуди кишварҳои Аврупои Шарқӣ ва Ҷанубу Шарқӣ, Русия, Қафқоз, Осиёи Марказӣ ва Ховари Миёна пахш мешаванд, беш аз 35 миллион шунаванда доранд.	https://www.rferl.org/img/podcastLogo.jpg
2973	http://feeds.feedburner.com/lcpodcast	Lake County (IL) Podcast	W. Guy Finley	News, reviews, commentary and diatribes on all issues concerning Lake County, Illinois.	http://www.feedburner.com/fb/images/pub/fb_pwrd.gif
2974	http://www.spreaker.com/user/4625977/episodes/feed	Indy Radio	Indy Radio	Sun \n12pm pst The Elephant Room\n\nMon \n6pm pst Mars Venus\n\nTues \n6pm pst The Spotlight\n7pm pst Talking about Walkers (the Walking Dead podcast)	http://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/9aac484f9f2210826c9b8928b5a084f6.jpg
2975	http://www.stillwaterbible.org/audio/podcast.php?sid=IS21	Temptation - SBC Podcast	JB Bond, Th.M.	A study explaining what temptation is and the Bible has to say about dealing with temptation.	https://www.stillwaterbible.org/audio/podcast.jpg
2976	http://feeds.feedburner.com/beyondthepedwayitunes	The Entrepreneurs Unpluggd	\N	Unfiltered, useful resources from entrepreneurs, for entrepreneurs	https://entrepreneursunpluggd.com/wp-content/uploads/2019/08/icon.png
2977	http://feeds2.feedburner.com/TvpSessionVideos	TVP Session Videos	Tanya Villano	Animoto music videos featuring highlights from portrait sessions with Tanya Villano Photography; pet photography, senior portraits, baby photography, belly photography.	http://2.bp.blogspot.com/_GN5HacZSzcs/SpQEZDNf_AI/AAAAAAAAAJM/qfZx3Yf3d4Y/S1600-R/bloggerbgd4.jpg
2978	http://podcasts.learningmarkets.com/scottrade-trader-podcast-series.xml	Learning Markets Trader Podcast Series	Learning Markets	Listen to market commentary and debate on the go with the Learning Markets Trader Podcast Series brought to you every Monday, Wednesday and Friday. Learning Markets Analysts watch the global markets so you get the complete picture and not just a glimpse.	http://podcasts.learningmarkets.com.s3.amazonaws.com/learningmarkets100.jpg
2979	http://feeds.feedburner.com/MensRoomPodcastPodcast	The Mens Room Daily Podcast	The Mens Room Daily Podcast	From sinners to saints, kings to commoners, rock stars and regular folks.  Everyone is here and they’re sharing their stories. Sit down and grab a beer with the men of The Mens Room.	https://www.omnycontent.com/d/playlist/4b5f9d6d-9214-48cb-8455-a73200038129/ad55078a-1211-4c94-a1c5-a93f000c724f/e6547190-6f28-43f3-884f-a93f000c7254/image.jpg?t=1537217940&size=Large
2980	http://feeds.feedburner.com/AmongTheDead	Among the Dead	David Maynard	Simon Richards is Kentucky man lost among the dead.	http://1.bp.blogspot.com/_foNeQ4GN1Hs/S70ncQlMd0I/AAAAAAAAAAM/POUB61PkzlI/S1600-R/amongthedead.jpg
2982	http://feeds.feedburner.com/PodcastJoffre	Podcast du Lycée Joffre	Lycée Joffre	Ce podcast relate les manifestations autour des prépas du Lycée Joffre de Montpellier (conférences, témoignages, Portes Ouvertes, etc...)	http://www.lyceejoffre.net/cpge/podcast/podcast.jpg
2986	http://feeds.feedburner.com/dlsopodcast	Podcast – Dance Like Shaquille O'Neal	DLSO	This is the podcast from dlso.it - From here you can listen to our exclusive music contents.	http://img804.imageshack.us/img804/9602/podcast.png
2988	http://feeds.feedburner.com/TempleBnaiShalomServicePodcasts	Services - Temple B'nai Shalom	Temple B'nai Shalom - Fairfax Station, VA	This podcast features the Shabbat and holiday services from Temple B’nai Shalom in Fairfax Station, Virginia. Temple B'nai Shalom is a vibrant, caring, and progressive Reform congregation established in 1986 to serve the needs of a growing Jewish community in Northern Virginia. We are led in prayer by Rabbi Amy R. Perlin, D.D.\r\n\r\nFor more information on TBS, visit our website: http://www.tbs-online.org\r\n\r\nFor a podcast that contains just the rabbi's sermons, check out this feed: http://itunes.apple.com/us/podcast/temple-bnai-shalom-sermon/id457865236	http://www.tbs-online.org/images/content/Service-Podcast-Icon-2.png
2989	http://beehray.podOmatic.com/rss2.xml	Paper People Jokes	Brandon Ray	Weekly jokes animated with construction-paper!  Submit a joke via comment or email, and it could be selected to be animated for an upcoming episode.  Animate a joke with paper, and it will be featured in a future episode!	https://beehray.podomatic.com/images/default/podcast-2-3000.png
2990	http://www.blogtalkradio.com/urbanjunglesradio.rss	Urban Jungles Radio	Danny Mendez	Urban Jungles Radio is a cutting edge radio/podcast program that explores various topics in reptile, amphibian and vertebrate care.  We feature celebrity guests	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzL2UzMmNhZWI3LWRkYjgtNDI2NS05Yzk2LWZlZjU3ZWEwYmUyZF91anJyZWQuanBn/e32caeb7-ddb8-4265-9c96-fef57ea0be2d_ujrred.jpg?mode=Basic
2993	http://www.prevention-sante.eu/feed/podcast/	Prévention Santé	deborahdonnier@gmail.com (preventionsante)	L'émission du bien-être et de la santé	https://www.prevention-sante.eu/wp-content/uploads/powerpress/psante1400.png
2995	http://loosebrucekerr.libsyn.org/rss	Loose Bruce Kerr's Parody/Original Song Podcast	Bruce Kerr	Parody & Original Songs of Loose Bruce Kerr as featured on the Dr. Demento & Jim Bohannon Shows	http://static.libsyn.com/p/assets/c/c/8/0/cc808d2e8ad60d53/Evangeline_Cover.jpg
2997	http://tvoutofthebox.thewb.com/paley-center-audiotour/english-podcasts.xml	English Audio Tour for Warner Bros.' Television: Out of the Box at the Paley Center for Media	Warner Bros.' Television: Out of the Box	Audio tour covering 23 different exhibits within the Paley Center for Media Warner Bros. exhibit.	http://tvoutofthebox.thewb.com/paley-center-audiotour/images/PaleyLogo.jpg
2998	http://www.blogtalkradio.com/frontdeckentertainment.rss	Fish Bait Radio Network™	Fish Bait Radio	Live outdoors Radio shows covering the best fishing action around. Covering both freshwater and saltwater fishing.\nAlso special guest covering products and tip	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzLzZmOTQzZmE4LWQzM2MtNDlhMy1hMTBiLTYwNWZiOTU3MTlkMl9ub2Ryb3BzaGR3LTQwMC5qcGc/6f943fa8-d33c-49a3-a10b-605fb95719d2_nodropshdw-400.jpg?mode=Basic
2999	http://prince35.podOmatic.com/rss2.xml	SOUL POWER DA MIXES PODCAST	PRINCE E	Funky soulful disco	https://prince35.podomatic.com/images/default/podcast-1-1400.png
3000	http://podcast.playbackmedia.co.uk/whistleblowers.xml	Whistleblowers - The Football Podcast	Playback Media Ltd	Football is our national sport, no matter where you're from! The Whistleblowers takes a weekly look at what's going on in soccer and is not afraid to blow the whistle on the controversies the newspapers are too afraid to report! Join him and his regular celebrity guests by subscribing now to see what the hell you're missing! *The Whistleblowers is brought to you by Playback Media, the makers of the Internet's most popular Arsenal, Spurs, West Ham, Rangers, Liverpool and Man Utd. podcasts, so you should know what to expect!	http://podcast.playbackmedia.co.uk/whistleblowers/images/iTunesArtwork@2x.png
3004	http://www.ndjt.hu/cast/podcast.xml	NDJT Project - The Podcast Series	NDJT Project	A podcast-et az NDJT Project, 3 lemezlovas készíti, amely havonta többször jelenik meg a kedvenc dalaikkal. A project tagjai: dL (Mészáros Dániel), Friend (Baráth Zoltán), és PinknoiZe (Pál Zoltán), hétről hétre az elektronikus zenei irányzatok legújabb megjelenésű darabjaiból válogat. |  The podcast by NDJT Project, the 3 Hungarian DJ Producer who made a special mixes in every mounth with her favorit tracks. Weboldalunk címe - site address: http://www.ndjt.hu Email cím - mail address: info@ndjt.hu Facebook: http://www.facebook.com/ndjtproject A műsorban elhangzott dalok listáját keresd a podcast leírásában.	https://www.ndjt.hu/cast/ndjtprojectcast.jpg
3005	http://fredbroom.podomatic.com/rss2.xml	Catholic Ignatian Marian Spirituality	Father Ed Broom, OMV, talks about Catholic Ignatian Marian Spirituality		https://assets.podomatic.net/ts/2e/b8/cb/calloftheking/3000x3000_7760776.jpg
3006	http://www.dayintechhistory.com/feed/podcast	Day in Tech History	geekazine@gmail.com (Jeffrey Powers)	I love history. That is why I started Day in Technology History podcast. It's a Daily rundown of events in science, tech and geek news. Find out what was released, in a chronological order. This Podcast is produced 7 days a week, 365 days a year. www.dayintechhistory.com	http://dayintechhistory.com/wp-content/uploads/powerpress/DITH-14-600.jpg
3007	http://srnoble.podOmatic.com/rss2.xml	Spanish with Sr. Noble	Jason Noble	Mini Spanish lessons in podcast format	https://assets.podomatic.net/ts/fd/ae/ba/srnoble/3000x3000_2525287.jpg
3009	http://feeds2.feedburner.com/urclearning/bc-audio	Belgic Confession Audio Recording from URC Learning	Rev. Tom Morrison	From URC Learning (urclearning.org): Audio recordings of one of the Three Forms of Unity, a most treasured summary of the Bible’s basic teachings.	http://urclearning.org/wp-content/themes/urcl-oasis/images/podcast_images/podcast_image_bc-audio.jpg
3013	http://www.radionz.co.nz/podcasts/extratime.rss	RNZ: Extra Time	RNZ	A review of the week in sport.	https://www.rnz.co.nz/assets/programmes/icons/169/1400_Extra_time_1400x1400.jpg?1542597060
3014	http://www.poderato.com/omarbs22/_feed/1	SALSA DURA (Podcast) - www.poderato.com/omarbs22	www.podErato.com	SALSA                          RUMBA                    SALSA\n                    MOVIDA                       SALSA\nDE                                  BARRIO                        \n               SALSA                  Y \n   MAS                                SALSA	http://www.poderato.com/files/images/28316l16323lpd_lrg_player.jpg
3015	http://feeds.feedburner.com/BlackCoffeeRadio	black coffee radio	noreply@blogger.com (Eddie Boles)	Listen to the best unsigned Hip-Hop artists in Southern California!	\N
3019	http://neolatin.lbg.ac.at/podcast/feed	Neo-Latin Podcast	Ludwig Boltzmann Institute for Neo-Latin Studies	Selected pieces from the world of Neo-Latin	http://neolatin.lbg.ac.at/sites/files/neulatein/images/podcast_logo.png
3020	http://voiceofbusiness.pearson.libsynpro.com/rss	The Voice of Business	FT Press	The Voice of Business features ideas and perspectives on the developing strategies for leadership, management, operations, human resources, marketing, sales and the global economy.	http://static.libsyn.com/p/assets/d/9/0/5/d9055bf3d396f9ea/soapy.jpg
3023	http://feeds.feedburner.com/blogspot/Vdue	Help Me, Bubby!	Help Me, Bubby!	An advice column weblog that offers advice from a 90-year old grandmother in response to questions emailed in by readers. Seven podcasts have been produced with Bubby's recorded advice.	http://www.helpmebubby.com/bubby.jpg
3026	http://www.formo.nl/flexican/feed.xml	The Flexican	The Flexican	2018 in a nutshell, was a whirl wind. It was a special year for me. I became father of a healthy babygirl, named Zya. I have released my “Come to me” single an Me EP . Travelled the world to DJ at amazing places. Today I finally give birth to the wonderful Yearmix of 2018. You have been waiting for a while now, but I have put my heart into it. Hopefully it has been worth the waiting. May you be delighted by my music selection of 2018. May it become a classic one! Enjoy! Yours Truly, The Flexican	http://www.formo.nl/flexican/TheWonderfulSoundsVol2whitecover1000x.jpg
3027	http://feeds.feedburner.com/TsportsBigBoardFriday	WTOL 11, Big Board Friday	WTOL 11	WTOL 11's Big Board Friday.  NW Ohio & SE Michigan's Premier High School Highlight and Scoreboard - WTOL.com, Toledo's News Leader,	http://www.3bproductions.org/Pods/BBFPodIcon.jpg
3028	http://thewellnesscouch.com/category/tps/feed	That Paleo Show	podcasts@thewellnesscouch.com (The Wellness Couch)	Dr Brett Hill (Chiropractor) is passionate about helping people get healthy naturally and believes that your body needs no help to perform at it’s best, just no interference. This show will help you get back to basics and redefine the way you eat, think, and move in order to maximise your innate potential.	http://thewellnesscouch.com/wp-content/uploads/2018/08/TPS-iTunes-img.jpg
3031	http://feeds.feedburner.com/podjournalen	PodJournalen	Karin Høgh (karin@podconsult.dk)	Karin Høghs podcast er personlige møder med danske podcastere. Deres passion for deres nicher og deres begejstring for mediet er til inspiration for andre til at begynde at podcaste. Karin Høgh holder online-kurser og er podcasting-konsulent med eget lydstudie coSounds. Se mere på PodConsult.dk	http://podconsult.dk/PodJournalen_144.jpg
3033	http://hearmanchester.com/hearmanchester.xml	hearmanchester.com	Vist Manchester	Join John Robb and over thirty special guests, ranging from politicians to body-poppers, psychogeographers to popstars as they explore the Rochdale Canal and Petersfield areas of Manchester.	http://hearmanchester.com/podcast/jpg/cover.jpg
3035	http://www.seaturtle.org/podcast/index.xml	Sea Turtle Multimedia Guide	SEATURTLE.ORG (mcoyne@seaturtle.org)	Multimedia logs from the world of sea turtle research and conservation.	http://www.seaturtle.org/imagelib/data/1DSCN6040-thumb.jpg
3036	http://site.afterbuzztv.com/cat_shows/nashville-afterbuzz-tv-aftershow/feed/	Nashville Reviews and After Show - AfterBuzz TV	AfterBuzz TV	The Nashville After Show recaps, reviews and discusses episodes of CMT's Nashville.\n\nShow Summary: Rayna James has had a successful country-music career, but lately, her popularity has started to fade. Her record label believes the solution is to have her open for up-and-comer Juliette Barnes on tour, but Juliette is a schemer and wants nothing more than to steal Rayna's spotlight. Rayna thinks her real chance is in another young woman, undiscovered songwriter Scarlett O'Connor. While Rayna struggles with her career, her father is busy messing with her private life, encouraging her husband to run for election to be mayor of Nashville – against her wishes.	https://d3t3ozftmdmh3i.cloudfront.net/production/podcast_uploaded_nologo/1050738/1050738-1537888184450-4b46716e1d74c.jpg
3039	http://www2.rozhlas.cz/podcast/podcast_porady.php?p_po=2408		Český rozhlas	iRadio	http://data.rozhlas.cz/api/v2/asset/edition/2408/1400x1400.jpg
3040	http://liveattheshow.altartv.libsynpro.com/itunes	Live	AltarTV	Live At The Show captures HD footage of the best concerts from around the globe.	http://static.libsyn.com/p/assets/d/9/0/5/d9055bf3d396f9ea/soapy.jpg
3041	http://www.radiocine.org/podcastRadiocine.xml	Radiocine, la radio del cine en Internet	www.radiocine.org (radiocine@radiocine.org)	Noticias, festivales, cine de autor, libros de cine, todo el cine en Radiocine (y en castellano)	http://win.radiocine.org/Podcast/ThiMai.jpg
3043	http://www.clubbingaway.co.uk/podcast/kavosnightlife/kavosnightlife_podcast.xml	Kavos Nightlife Official Podcast	Kavos Nightlife	KavosNightlife presents: The Official Kavos Nightlife Podcast!  Your daily / weekly / monthly fix of Kavos official mixtapes.  Sit back and enjoy and re-live the memories.	http://www.clubbingaway.co.uk/podcast/kavosnightlife/podcast-artwork-2015.jpg
3045	http://feeds.feedburner.com/NewLifeChurchPodcasts	New Life Church Podcasts	New Life Church	Welcome to the audio Podcast from Dr. Darrell Huffman. Dr. Huffman is pastor of New Life Church in Huntington, WV - a growing Word of Faith church that emphasizes training and equipping people to fulfill Gods purpose for their life.	http://www.nlconline.org/images/DHPodcast.jpg
3047	http://atastyle.podOmatic.com/rss2.xml	D&W Origins	AtA AxelTheAs	Podcasts of the portable designed serie : Dragon and Weed : Origins.	https://assets.podomatic.net/ts/38/95/e6/atastyle/3000x3000_2555255.jpg
3050	http://feeds.feedburner.com/TheGroovePodcast	The Groove Podcast	The Groove	The Groove is het danceprogramma van Merweradio. Kijk voor meer informatie op the-groove.nl!	http://www.the-groove.nl/images/podcast.jpg
3051	http://feeds.feedburner.com/7PhotographyQuestions	7 Photography Questions	7PhotographyQuestions.com	Join Dr. Audri Lanford each Tuesday as she interviews world class photographers and gets dynamic, practical, and entertaining answers to 7 essential questions in each photographer's specialty. Find show notes, etc. at 7PhotographyQuestions.com.	http://www.7photographyquestions.com/7_photography_questions.jpg
3054	http://www.audiodramax.com/?feed=podcast	AudioDramax	AudioDramax	Audiodramax est un collectif de créateurs de fictions sonores. Laissez-vous emporter, plongez au cœur d’enquêtes, d’aventures, de découvertes… De la Science-Fiction et du Fantastique en Podcast.	https://www.audiodramax.com/images/audiodramax_podcast1400.jpg
3058	http://www.islamhouse.com/pc/230552	Vetëllogaria	IslamHouse	Njeriu duhet ta fisnikëroj shpirtin e tij, duhet të përkujdeset për punën e tij nëse dëshiron që Allahu ta blejë atë nga të dhe ta begaton me begatinë e tij.<br />\nE ajo që më së shumti ndihmon në këtë dhe që duhet të jetë myslimani i vëmendshëm për të është vetëllogaritja. Prandaj si ta arrijmë këtë është edhe tema e kësaj ligjërate.<br />	http://islamhouse.com/islamhouse-sq.jpg
3060	http://www.spreaker.com/user/4990310/episodes/feed	iSenaCode Podcast	iSenaCode Podcast	Red de podcasts del grupo iSenaCode	http://d1bm3dmew779uf.cloudfront.net/big/81a395b82f46b6be7f91de124c3c9bbc.jpg
3061	http://inside-av.com/rss.xml	Inside AV	Andrew Hutchison & Keith Clifford	From High End Audio to Sound Bars. HiFi, AV and Custom Install are all discussed by two professionals with 70 years industry experience.	http://inside-av.com/graphics/insideav_pcast_banner_003.jpg
3062	http://slscast.podbean.com/feed/	The SLS Cast	TM & Copyright SLS Productions, LLC 2020	An all film podcast featuring your hosts Matt & Tim. There will be discussion of all genres, both classic and current, as well as movie news, and even bonus segments like '3².' You're bound to enjoy it!	https://pbcdn1.podbean.com/imglogo/image-logo/363062/SLSLogo4-18.png
3088	http://feeds.feedburner.com/CFAChallengePodcast	CFA Institute Research Challenge Podcast	Research Challenge	The CFA Institute Research Challenge is an annual educational initiative promoting best practices in equity research among finance students across the world.	https://assets.podomatic.net/ts/39/75/e7/researchchallenge/3000x3000-0x0+0+0_6598996.gif
3066	http://www.beyondpatmos.org/rss/rssitunesvideo.xml	Beyond Patmos Video Podcasts	Beyond Patmos	FREE Christian video and audio resources! Featured speakers like Mark Finley, David Asscherick, Shawn Boonstra, David Gates, and many more. Topics include Better Living, Christian Ministries, Testimonies, Prophecies and Revelation/End time events and many more. Please visit website for more information.	https://www.beyondpatmos.org/images/itunes-podcast-logo.jpg
3067	http://site.afterbuzztv.com/cat_shows/the-fosters-afterbuzz-tv-aftershow/feed/	The Fosters Podcast	AfterBuzz TV	The Foster After Show Podcast recaps, reviews and discusses episodes of Freeform's The Fosters.\n\nShow Summary: The series follows the lives of police officer Stef Adams Foster and her wife Lena Adams Foster, a school vice principal, and their multi-ethnic, blended family. Stef and Lena are the parents of Brandon Foster, who is Stef's biological son, and the twins, Jesus and Mariana, who were adopted as small children. At the outset of the series, the couple take in two foster children, Callie and Jude, whom they later adopt.	https://d3t3ozftmdmh3i.cloudfront.net/production/podcast_uploaded_nologo/1050958/1050958-1537887163962-d296c070e59c1.jpg
3068	http://www.clcdenhaag.nl/~podcast/podcastfeed.xml	City Life Church Den Haag	City Life Church Den Haag	De officiële podcast van City Life Church Den Haag. Mensen in contact brengen met God en Zijn kerk; ze helpen zich te ontwikkelen en ontplooien, zodat ze het beste uit hun leven kunnen halen en zodat zij een verschil kunnen maken in hun wereld. Inspirerende en opbouwende boodschappen en praktische tips om het beste te halen uit je dagelijks leven!	http://www.clcdenhaag.nl/~podcast/podcast2015.jpg
3070	http://rss.dw-world.de/xml/DKpodcast_lernerportraet_de	CommunityD – Lernerporträt | Deutsch lernen | Deutsche Welle	DW.COM | Deutsche Welle	Ob in Estland, Japan oder Brasilien – Menschen, die Deutsch als Fremdsprache lernen, gibt es überall auf der Welt. Sie interessieren sich für Deutschland und die deutsche Sprache. Hier stellen sie sich vor.	https://static.dw.com/image/15438124_7.jpg
3071	http://feeds.feedburner.com/GoodNewsMagazine	Good News Magazine	\N	Vi är en svensk community som delar positiva nyheter som inspirerar och engagerar.	https://goodnewsmagazine.se/img/core-img/gnm-logo.png
3073	http://feeds.feedburner.com/NWCZRadioMegaMix	RSSMix.com Mix ID 2410669	NWCZRadio.com	Welcome to NWCZradio.com! We are not what you are hearing on “the air”. It is our goal to bring you the best in northwest independent music whether it be rock, punk, hip/hop, techno, blues, jazz, etc. All the music you hear on our station is by independent artists who deserve to be heard. You can go out and see them on any given weekend around this great northwest and now you can hear them here as well.  We define the northwest as including British Columbia, Washington, Oregon, Idaho and surrounding areas.  If you are an independent artist and would like to be heard please contact us at nwczradio@gmail.com and we’ll let you know how to get your music to us so we can get it to the people! Listen in, tell your friends and let’s all join the independent radio revolution!!!!!!	http://nwczradio.com/wp-content/uploads/2011/05/NWCZRadio-Logo.jpg
3075	http://stlukeshouston.libsyn.com/rss	St. Luke's United Methodist Church - Houston, Texas		Worship services that are relevant, passionate, and life-changing.\n\nA choice of both traditional and contemporary worship styles.\n\nAn invitation to live a life that matters…to make a difference!\nSt. Luke’s United Methodist Church wants to make a real difference in your life – in your spiritual life, in your relationships, and in the city and world.\n\nWhether you’re young or old, single, married, single again, with or without children, St. Luke’s has a place for you! We invite you to experience the difference here.	https://ssl-static.libsyn.com/p/assets/4/1/4/d/414d2a655fbb55ac/StLukesUMC-PodcastLogo.jpg
3076	http://www.freedomhousechurch.sitewrench.com/swx/pp/media_archives/74391/channel/1156.xml	Freedom House Church Podcast	Tracie Frank	Welcome to Freedom House Church's weekend service messages. To learn more about us, visit www.FreedomHouse.cc	http://www.freedomhousechurch.sitewrench.com/assets/1345/fh-vimeo-image.jpg
3077	http://feeds.feedburner.com/tbcfdl-podcast	Trinity Baptist Church Sermon Audio	Pastor Dan Leeds	Trinity Baptist Church places a high importance on the preaching of the Word of God, because God has chosen to use the preaching of the Word of God to save souls.  We invite you to expose your life to the sharp edge of the Word of God so that you might accomplish what God would want you to accomplish in your life.  Pastor Dan Leeds, the primary Sunday morning preacher, works exegetically and systematically through books of the Bible on Sunday mornings.	http://trinityfdl.net/audio/podcast.jpg
3078	http://downloads.bbc.co.uk/podcasts/fivelive/money/rss.xml	Wake Up to Money	BBC	News and views on business and the world of personal finance. Plus the very latest from the financial markets around the globe	http://ichef.bbci.co.uk/images/ic/3000x3000/p07pqclg.jpg
3079	http://feeds.feedburner.com/AindaSemNomePodcast	Podcast – Ainda Sem Nome	Caio Cesar	Toda semana conversamos sobre comunicação online. O mercado, os profissionais, as ações e tudo o mais que se relacionar a estes assuntos!	http://aindasemno.me/aindasemnome.png
3080	http://feeds.aljazeera.net/podcasts/thestreamHD	The Stream - HD	Al Jazeera English	The Stream taps into the extraordinary potential of social media to disseminate news.	http://feeds-custom.aljazeera.net/en/images/programmes/thestream_600x600_logo_HD.jpg
3081	http://www.screencast.com/users/MrGundrum/folders/AP%20Chemistry%20Vodcasts/rss	AP Chemistry Vodcasts	\N	Slinger High School AP Chemistry Vodcasts\nMrGundrum	\N
3082	http://feeds.feedburner.com/Oasis-Church-NJ	Christian Dating Service Reviews | Dating Advice | Christian Singles Podcasts	David Butler @ Oasis-Church-NJ.com (david@oasis-church-nj.com)	Christian messages on dating, relationships, finances and marriage and life brought to you by Oasis-Church-NJ.com	https://christian-dating-service-plus.com/wp-content/uploads/powerpress/OA.png
3084	http://mwydro.podomatic.com/rss2.xml	Mwydro ym Mangor	Jonathan Ervine	Podlediad am Ddinas Bangor a phêl-droed yn y byd Cymraeg.	https://assets.podomatic.net/ts/45/a7/18/jonathan-ervine/1400x1400_4765950.jpg
3085	http://feeds.feedburner.com/SmallDogElectronicsPawcast	Small Dog Electronics Pawcast	Ed Shepard (ed@smalldog.com)	Leading Apple Specialists discuss all things Apple, including iPod, Mac OS, and running a Mac-based business in a fun, conversational manner. Occasional dog-related banter, too.	http://images.smalldog.com/podcast/pawcast_badge.jpg
3086	http://www.radiovaticana.va/rss/francese.xml	Radio Vatican - Clips-FRE	webteam@vaticanradio.org	La production de Radio Vatican en Podcast	http://www.radiovaticana.va/RSS/logo_pod_news_fra.jpg
3087	http://www.banjohangout.org/rss/Genres-Top-ID2.xml	Banjo Hangout Top 100 Classical Songs	Banjo Hangout	Top 100 Classical Songs banjo songs which Banjo Hangout members have uploaded to the website.	https://www.banjohangout.org/img/podcast-logo.jpg
3089	http://www.poderato.com/saludmental/_feed/1	Salud Mental El Podcast (Podcast) - www.psicoterapias.mx/	Psic. Gus Novelo	Noticias de Psicología, de todos los temas y para todo público.	http://www.poderato.com/files/images/14733l8126lpd_lrg_player.jpg
3091	http://newlifechurch.me/Media/MediaXML.xml?fid=662	New Life Christian Church Video Podcast	New Life Christian Church	Video Podcast from New Life in Emsworth	https://www.newlifechurch.me/Images/Content/1143/305087.jpg
3093	http://feeds.feedburner.com/typepad/showmeyourtitles	Show Me Your Titles film podcast	Show Me Your Titles film podcast	Cathy and Erin review movies and discuss current film news and trends.	http://www.feedburner.com/fb/images/pub/fb_pwrd.gif
3094	http://podcast.rmc.fr/channel243/RMCInfochannel243.xml	RMC : After JO	RMC (lewebmaster@rmc.fr)	Le debrief de la journée en direct du club France avec la dream team et les médaillés français du jour en direct	https://frontrmcimg.streamakaci.com/images/200_podcasts_afterjojpg_20120720175154.jpg
3096	http://www.spreaker.com/show/597449/episodes/feed	BACK2BLACK	BACK2BLACK	"Good Music Makes Good People" • Hip Hop • Rap • Soul • R&B • Funk • Jazz • Reggae • & more..	http://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/52050ec6dc3e8463986147daabf924db.jpg
3098	http://feeds.feedburner.com/weatherbrains	WeatherBrains	The Weather Company (wo4w@me.com)	A weekly podcast for people who love weather. A team of meteorologists discuss current weather events and hot topics involving meteorology.	http://www.weatherbrains.com/graphics/weatherbrainsitunes.jpg
3103	http://www.blogtalkradio.com/follow-your-bliss/podcast	Follow Your BLISS to Author Success	Ronda Del Boccio Story Lady	Welcome! Are you ready to follow your B.L.I.S.S. to author success?\n\nI'm #1 bestselling author and Celebrity Author Mentor Ronda Del Boccio, You can find me a	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzLzU3ZWNhZTNmLWZjYzMtNDkwOS04MWY4LTFjNmZmNTkyMDdjMl9mb2xsb3d5b3VyYmxpc3NfMTAwLmpwZw/57ecae3f-fcc3-4909-81f8-1c6ff59207c2_followyourbliss_100.jpg?mode=Basic
3106	http://feeds.feedburner.com/dosxlpodcast	Dos XL Podcast	JossGreen	La informacion tecnologica como realmente la quieres escuchar, presentado por JossGreen	http://publicared.com/2xl/2xlnvo.jpg
3107	http://podcast.rthk.org.hk/podcast/headlinerwing_i.xml	香港電台：頭條新聞 - 白做群英	RTHK ON INTERNET		http://podcast.rthk.org.hk/podcast/upload_photo/item_photo/170x170_211.jpg
3108	http://feeds.feedburner.com/ItsAPurlMan	It's a Purl, Man » Podcast Feed	Guido (2Skiens) Stein (2Skiens@itsapurlman.com)	A knitting podcast about a guy from Boston with yarn issues. Every week I share my projects and as much of the Boston knitting experience as I can fit into my show.	http://www.itsapurlman.com/itsapurlman_com.png
3109	http://soyouwannabearapper.podOmatic.com/rss2.xml	So you wanna be a rapper?	Soyou Wannabearapper	So you wanna be a rapper? Then you wanna check out this new podcast. Breaking down the basics for the budding lyricists of the webernet.	https://soyouwannabearapper.podomatic.com/images/default/podcast-3-3000.png
3112	http://wemu.org/podcasts/9730/rss.xml	Cinema Chat from WEMU	WEMU	Host David Fair sits down with Michigan Theater Executive Director Russ Collins for a most entertaining conversation on movies, culture and live events to be experienced in the local area.	https://www.wemu.org/sites/wemu/files/styles/npr-feeds-podcast-cover-art/public/201904/WEMUpodcast-3.jpg
3115	http://www.islamhouse.com/pc/236174	Komentar Vasitijske akide	IslamHouse	Vasitijska akida - pisca Šejhul Islama Ibn Tejmijje, r.h. - je od najkvalitetnijih djela koja obrađuju akidu ehli sunneta vel džemata, iako je knjiga veoma malog obima ali je zato veoma precizna u izražaju. Zbog toga su učenjaci i daije ulagali trud da komentarišu ovu knjigu, i od tih komentara je i ovaj od našeg poznatog daije Jusufa Barčića, r.h.	http://islamhouse.com/islamhouse-sq.jpg
3116	http://feeds.feedburner.com/ChinesePodcastSocietyAndCulture	TEDTalks 社会与文化	TED (contact@ted.com)		https://pc.tedcdn.com/distribution/rss/images/TED_Collections_Society_and_Culture_CN.png
3117	http://walleye.outdoorsfirst.com/podcast	WalleyeFIRST.com Radio	OutdoorsFIRST Media (info@outdoorsfirst.com)	WalleyeFIRST Radio, covering the world of walleye fishing and walleye tournament fishing.	\N
3118	http://feeds.feedburner.com/ask13	Cinema Diabolica	Cinema Diabolica (cinemadiabolica@gmail.com)	On Cinema Diabolica we review and pick apart the best (and worst) in lesser known, Horror, Giallo, Exploitation, and worldwide Cult Cinema. Call in all your questions and 60 second reviews to our voicemail line: 206.350.4030	http://static.libsyn.com/p/assets/8/f/2/3/8f2312c975ab5375/SHOWICON.jpg
3119	http://rpg.podspot.de/rss	RPG Cast	RPG-Cast-Team	RPG-Cast ist ein Podcast über TV-News, Kinotipps, Medien und Kuriosen Dingen aus dem Web!	\N
3120	http://tpenetwork.com/feed/rht.xml	Relationship Hot Topics	TPE Network	Join writer and former professional athlete Hank Davis, Rebecca Ryder, Big Mike, XD and others from TPE Network as they discuss topics relating to relationships, dating, marriage, divorce, love and sex. The cast from TPENetwork.com deliver a fun yet informative take on love.	https://tpenetwork.com/image/xmlpic/rht1400.jpg
3182	http://audioboo.fm/users/16510/boos.rss	Ed Dale's posts	Audioboom	Ed Dale's recent posts to audioboom.com	http://assets.theabcdn.com/assets/ab-wordmark-on-blue-600x600-d99e66d8a834862dec08e4f3cd1550b575254fb4b38902fb07ef5af5f0aeb21f.png
3124	http://www.thementes.com.br/category/thementespodcast/feed/	TheMentes Podcast – TheMentes	TheMentes	TheMentes - Blog, Podcast e VideoCast sobre os mais variados temas desde Animações, Jogos, Animes, Mangás, Live Action, Música, Filmes, Quadrinhos e Cultura Nerd	http://www.thementes.com.br/imagens/podcast.png
3129	http://www.sermonaudio.com/rss_search.asp?keyword=baptism&keyworddesc=Baptism	Baptism on SermonAudio	Baptism	The latest podcast feed searching 'Baptism' on SermonAudio.	https://www.sermonaudio.com/images/sermonaudio-new-combo2-1400.jpg
3130	http://www.israelnationalnews.com/Radio/Rss.ashx?act=1&cat=11	Israel National Radio - Walter's World	tech@israelnationalradio.com	Walter Bingham travels all over Israel and the international Jewish world to bring you in-depth reports in his exciting magazine style program. Topics range from cultural and entertainment events and social problems to major political interviews and statements recorded live as they happen. He holds up a mirror at Jewish life and paints pictures in sound. His many famous guests have included Alan Dershowitz, Chief Rabbi Lord Sacks, Charles Krauthammer, John Bolton, German film star Iris Berben, Jewish community heads of many countries, singing and entertainment stars Dudu Fisher, Yaffa Yarkoni, Theodor Bikel, David D'Or as well as many politicians, political commentators and academics.  Walter's World broadcasts every Friday early morning 1am U.S. EST / 8am Israel time on Israel National Radio. Walter can be emailed at walter@israelnationalradio.com and his last 20 shows are listed on the archive page.	http://www.israelnationalnews.com/Radio///a7.org/pictures/210x70/463605.jpg
3131	http://www.blogtalkradio.com/hrtalksback.rss	HR Talks Back	Archive	Interviews with HR  and Talent Management Leaders around the world about the key issues that matter to them.<br /><br />Also check out my other podcast show, Talking HR (<a href="http://www.blogtalkradio.com/talkinghr)" rel="noopener">http://www.blogtalkradio.com/talkinghr)</a>	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/c61d8c088d793698d3ae4bb1dcefbc6e.jpg
3132	http://feeds.feedburner.com/yoyomapodcast	An Intimate Tour Through The Music of Yo-Yo Ma » An Intimate Tour Through The Music of Yo-Yo Ma	Yo-Yo Ma	The official podcast series of cellist Yo-Yo Ma.	http://www.yo-yoma.com/podcast/yoyopodcastseries.jpg
3133	http://www.radionikkei.jp/podcasting/trend.xml	マーケット・トレンド	ラジオNIKKEI (webmaster@radionikkei.jp)	毎日夕方に15分生放送。\n（月）「世界の経済・政治ニュースから」\n（火）「小次郎講師のトレードラジオ講座」\n（水）「専門家の目（コモディティ・マーケットの見通しなど）」\n（木）「専門家の目（投資経験者のためのα情報など）」\n（金）「岡安盛男のFXトレンド」 と、日替わりで最新の投資情報をお届けします。\nいちはやくライブで、いつでもオンデマンドやポッドキャストでお聴きください。\nキャスターは山本郁、大橋ひろこ、辻留奈が担当いたします。	http://www.radionikkei.jp/archives/program/trend/podcast.jpg
3134	http://wearemastersystem.podOmatic.com/rss2.xml	We Are Master System - WAMScast	We Are Master System	We Are Master System mix a selection of the dirtiest electro for you every week...download and get listening	https://assets.podomatic.net/ts/da/e3/1a/wearemastersystem/3000x3000_2511114.jpg
3135	http://feeds.feedburner.com/TWIBS	TWIBS-This Week In BS	Leif and Jesse	We talk about all things BS, including news, and our opinions on the current political trends.  If you have anything to add, send us a message, http://twitter.com/leifandersen or http://twitter.com/bdsb525.	http://ia360929.us.archive.org/2/items/TWIBS/TWIBS.jpg
3138	http://neallogan.podomatic.com/rss2.xml	DJ Logan's Podcast	DJ Logan	DJ Logan bringing you the best DJ mixes...	https://assets.podomatic.net/ts/7a/9c/ad/neallogan/3000x3000_14745844.jpg
3139	http://m.minhaj.org/i/sph_mp3_English.php	English Speeches by Dr Tahir-ul-Qadri	Dr Tahir-ul-Qadri	Shaykh-ul-Islam Dr Muhammad Tahir-ul-Qadri has authored one thousand books in Urdu, English and Arabic languages. About 425 of these books have been printed and published while 575 books are in the pipeline, undergoing various processes of publication. Some of these books have also been translated in many other languages of the world. His revivalist, reformative and reconstructive efforts and peace dynamics bear historic significance and hold an unparalleled position in promoting the cause of world peace and human rights, propagating the true Islamic faith, producing prodigious research work and preaching the teachings of the Quran and Sunnah.	http://m.minhaj.org/i/imgs/1/qi.jpg
3140	http://stphilipscathedral.podcastpeople.com/rss/xml/2	The Cathedral of St. Philip	The Cathedral of St. Philip	Grace to you, and peace, in Jesus Christ our Lord! We hope these sermons and presentations will inspire you to love and good works. We also encourage you to visit the Cathedral of St. Philip for worship, prayer, and Christian community. There is a place for you here!	http://stphilipscathedral.podcastpeople.com/show/itunes_cover/7217/Podcast-iTunes-logo.png
3141	http://feeds.feedburner.com/luisavalmorisen	Luisa Valmori-Sen: Latest Recordings	Luisa Valmori-Sen	Luisa Valmori-Sen - concert pianist based in London, UK.	http://www.luisavalmorisen.com/images/rss_thumb.jpg
3143	http://www.voaindonesia.com/podcast/video.aspx?count=50&zoneId=411	Laporan VOA - Voice of America | Bahasa Indonesia	Voice of America	Beragam laporan berita informatif yang disajikan oleh tim VOA di Washington dan ditayangkan setiap Senin hingga Jumat pagi di Metro TV.	https://gdb.voanews.com/519D3535-AF34-46CC-9372-A44359703F23.png
3144	http://spacemusic.libsyn.com/classic	Spacemusic (Season 1)	spacemusic.nl	Spacemusic brings you the best of electronic (dance)music, interviews with great musicians, soundseeing tours in the City of Rotterdam, entertainment for everyone. Perfect music and atmospherics that keeps you company at your work, in your car, in your bed. Enjoy!	https://ssl-static.libsyn.com/p/assets/9/5/d/d/95dd0356ed38548e/S1-1400.jpg
3147	http://www.spreaker.com/show/407266/episodes/feed	Radio Sat Nam	Radio Sat Nam	Radio Sat Nam parla di Kundalini Yoga, Meditazione, Mantra, Spiritualità. Prodotto dal Centro Yoga Sat Nam Roma >> <a href="http://www.satnam.it" rel="noopener">www.satnam.it</a>	http://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/add13bbdcd2f09bf19b5ad30ff522323.jpg
3150	http://feeds.feedburner.com/LandOfSound	Land Of Sound	Maciej Wiosna	Land Of Sound\r\nStrategie nauki języka angielskiego, recenzje, porady, sztuczki, skuteczna i efektywna nauka.	http://a6.sphotos.ak.fbcdn.net/hphotos-ak-ash4/188758_200488263306315_200069146681560_614499_5285509_n.jpg
3184	http://podkast.nrk.no/program/p3morgen.rss	P3morgen	NRK	Adelina og Martin gir deg en god start på dagen hver morgen!	https://gfx.nrk.no/5HzsrlLb5vM5mZiWa9QPQAEzNEGIYgn6KoA_NwQwzhUw.jpg
3151	http://www3.nhk.or.jp/rj/podcast/rss/persian.xml	Persian News - NHK WORLD RADIO JAPAN	NHK (Japan Broadcasting Corporation)	This is the latest news in Persian from NHK WORLD RADIO JAPAN. This service is daily updated. For more information, please go to https://www3.nhk.or.jp/nhkworld/.	https://www3.nhk.or.jp/rj/images/persian_1500x1500.png
3154	http://bluenotestudios.com/casts/random-inspirations/feed	Random Inspirations	Random Inspirations	Random Inspirations and the effects of the Solar System on Global Warming	\N
3155	http://feeds.feedburner.com/mnitunes	Major Nelson Radio	Larry Hryb (Major@xbox.com)	Direct from inside the Microsoft Xbox team, Larry Hryb (Xbox Live Gamertag: Major Nelson) discusses Xbox, Xbox Live, Xbox  gaming, technology, other gaming platforms (including the Playstation, and Nintendo), and much more in his weekly podcast. The only podcast direct from Xbox.	https://majornelson.com/wp-content/uploads/sites/7/2020/08/CXC_MNRadio_3000x3000.png
3156	http://feeds.feedburner.com/IssuesClasses	Issues Classes	Eli McCulloch (noreply@blogger.com)	Recordings of the Adult Issues class at Derry Presbyterian Church, Hershey PA	\N
3157	http://feeds.feedburner.com/snobsaptesetpasbons	My Blog	Clarence Dutilleul	"Snobs, aptes et pas bons", le hype subversif mais anti-sacrificiel.	http://snobs.ablaze.fr/logo.jpg
3160	http://feeds.aljazeera.net/podcasts/talktoaljazeeraHD	Talk to Al Jazeera	Al Jazeera English	Al Jazeera journalists sit down with top newsmakers from around the world.	https://www.aljazeera.com/wp-content/uploads/2020/09/4eb43f682ba349649cad726f89ac5786_7.jpg
3162	http://thebittersound.jellycast.com/podcast/feed/16	The Spectacular Mango Chuffy Show	Kat Sorens	Kat and Jenni Sorens are not your average Australian couple, and this is not your average podcast. Pour yourself a glass of your favourite drink and relax whilst they tell you about their lives and more often than not, their sex lives. This is an adults-only podcast so listener discretion is very much advised.	https://thebittersound.jellycast.com/files/iTunes%20logo.jpg
3163	http://feeds.feedburner.com/mousemagichd	Mouse Magic HD (Apple TV)	Paul @ MouseMagicHD	Mouse Magic HD is a High Definition Video Podcast that brings Walt Disney World in Orlando, FL into your home.	http://www.mousemagichd.com/images/logo-1400.png
3165	http://www.blogtalkradio.com/mrpres26.rss	mrpres26	mrpres26	I also talk about current events, politics, law, music, and sports.	https://www.blogtalkradio.com/api/image/resize/1400x1400/aHR0cHM6Ly9kYXNnN3h3bWxkaXg2LmNsb3VkZnJvbnQubmV0L2hvc3RwaWNzL2NiNjUxOTk4LTE3ZmQtNGUwNS1iYWE3LWRhZGJjMWNiZjRhZl9pbWdwMjExNS5qcGc/cb651998-17fd-4e05-baa7-dadbc1cbf4af_imgp2115.jpg?mode=Basic
3166	http://www.ibm.com/podcasts/software/websphere/connectivity/index.rss	IBM WebSphere Connectivity and Integration Podcast Series	IBM WebSphere Software	Understand why IBM WebSphere Software can deliver comprehensive connectivity and integration that tames complexity, drives innovation, and gets you closer to your customers.	http://www.ibm.com/podcasts/software/websphere/connectivity/i/ibm_podcast.jpg
3169	http://www.maedchensprechstunde.com/PodcastMaedchenMP3/podcastmaedchenmp3.xml	podcastmaedchenmp3	Christian Rogl-Nemetz & Die Quadratur GesmbH (c.rogl-nemetz@die-quadratur.at)	Die Mädchensprechstunde wurde vom Berufsverband der österreichischen Gynäkologen ins Leben gerufen. Alle Mädchen sollen Zugang zu Informationen mit hoher Qualität und Verlässlichkeit erhalten. Dazu werden einerseits österreichische Gynäkologen und Gynäkologinnen eine eigene Mädchensprechstunde anbieten. Andererseits wird die Homepage www.maedchensprechstunde.com geschriebene und eben auch gesprochene Informationen bieten. \n\nWir laden alle Mädchen ein sich mit Fragen oder eigenen Beiträgen, Anregungen selbst zu beteiligen. Junge Mädchen sollen hier verlässliche Antworten über ihren Weg zum "Frau" werden erhalten. Interessant ist dieser PodCast wohl auch für Jungs, die sich für Mädchen interessieren.\nDie aufgearbeiteten Themen stammen auch von unseren Partnern des Institutes für Sexualpädagogik, welche seit Jahren auch in Schulen und auch über Internet jede Frage beantworten. Aus diesen Erfahrungen heraus entstanden zB auch die Episoden über die Sexlügen.\nWeitere Episoden findet ihr unter www.maedchensprechstunde.com oder unter iTunes. PodCasts und HörLeseBücher gibt es auch zu anderen Themen - beispielsweise medizinische Erkrankungen - unter www.hoerlesebuch.com oder unter www.die-quadratur.at. Weitere Informationen findet ihr auch unter www.sexualpaedagogik.at oder unter www.mein-frauenarzt.at.\nFür Fragen, Anregungen, Informationen oder einfach Lust selbst die Sendungen mit Beiträgen mitzugestalten meldet Euch bitte mit dem Stichwort "mädchensprechstunde" bei podcast@die-quadratur.at.	http://www.maedchensprechstunde.com/PodcastMaedchenMP3/
3170	http://feeds.feedburner.com/brpc	Bloody Rose PodCast	Jimmy Bloody Rose	Σε Μπλε Και Μαύρο Ηχόχρωμα Blue Black Soundcolour	http://bp1.blogger.com/_YDqK_6iZU5E/RyJdON_FeAI/AAAAAAAAAIc/h2LYOS15k-g/s400/BRPC3.jpg
3171	http://el.minoh.osaka-u.ac.jp/flit/public/zh/c_voc200/zh_voc200.xml	大阪大学「外国語+IT講座」中国語 基本語彙200	郭修靜	『基本語彙200』の各単元の音声は約2～3分、長くとも5分です。空いた時間に、できるだけ繰り返し聞く練習をしましょう。音声データはA,B二組に分かれており、特にA組の100語は最もよく使う語です。全ての語に、日本語と中国語の音声のあるもの、中国語の音声のみのものの二種類があります。最初は日本語の音声のあるものから聞き、繰り返し練習して、中国語のリズムや発音に慣れてください。最初は無理にリピートしようとせず、正確な発音を理解するよう努めましょう。慣れたら、中国語の発音を聞いて意味をとる練習、さらに日本語を聞いて中国語の発音をする練習と、レベルアップしていってください。	http://el.minoh.osaka-u.ac.jp/flit/public/zh/c_voc200/flit_2_zh_logo.jpg
3173	http://feeds.feedburner.com/tugandpullpodcast	Tug and Pull Podcast	Tiffany and AJ	Join hosts Tiffany and AJ along with their crew and some guests as they talk about all things lifey and stuff. No subject is immune from the ire and wreckless mockery! Follow the hosts on twitter: @AJ_TnP @Tbrain13	http://tugandpullpodcast.files.wordpress.com/2012/01/tugandpull-logo.jpg
3174	http://www.lullabot.com/blog/podcasts/the-creative-process/feed	The Creative Process	Jared Ponchot	A podcast dedicated to geeking out on the processes that help creative ideas become things.	https://www.lullabot.com/sites/default/files/shows/c8dec10e-20b8-11e5-91de-be444affd7ad.jpg
3177	http://www.loopz.fr/loopz.xml	Loopz-cast	Loopz-fr (gael@loopz.fr)	House, deep house, nu-disco podcast	https://www.loopz.fr/images/loopz-fr.jpg
3178	http://feeds.feedburner.com/LesChroniquesconomiquesDeBernardGirard	Les chroniques économiques de Bernard Girard	Bernard Girard	Chroniques économiques sur l'actualité prononcées chaque mardi matin sur AligreFM, une radio parisienne	\N
3181	http://myradio.hk/podcast/?feed=podcast	MyRadio.HK	myradio.tech@gmail.com (MyRadio.HK)	MyRadio.HK - Proletariat Political Institute	http://myradio.hk/wp-content/uploads/2016/02/myradio_1400x1400.jpg
3185	http://feeds.feedburner.com/blogspot/CCXX	LAME	Jordan B.	LAME- a weekly discussion about the Christian music world and its relevance to today's young generations. Hosted by college students, the show selects artists to feature each week. The backgrounds of the artists are discussed, as well as the inspiration for their music and what artist shares a similar sound in the secular music world.	http://www.freewebs.com/buckeytucker/LAME/Cast%20Image.jpg
3189	http://feeds.feedburner.com/dantegebel_podcast	Dante Gebel Podcast	LDMS	Descarga las predicas del Pastor Dante Gebel. Autor: LDMS/	http://static-2.ivooxcdn.com/canales/3/8/3/2/6011470822383_XXL.jpg
3190	http://pod1.podspot.de/rss	Wolfgang Ronzal - Wie Sie Kunden zu Partnern machen	Micheal Ehlers Verlag	Der Weltbestseller von Wolfgang Ronzal nun auch als Podcast und Hörbuch.\r\nDer zufriedene Kunde ist Ihr Kapital und das Potential Ihres Unternehmens.\r\nJeder unzufriedene Kunde bedeutet Negativpropaganda für Sie und Ihr Unternehmen. Wie Sie aus Ihren Kunden Partner machen, erfahren Sie in diesem Hörbuch. Der Weg dazu ist verblüffend einfach, wenn Sie einige grundlegende Punkte berücksichtigen und diese auch umsetzen. Wolfgang Ronzal zeigt Ihnen unter anderem: \r\n\r\nWas unter Servicequalität zu verstehen ist. \r\nWarum Reklamationen für Sie ein Vorteil sind. \r\nWarum Ihre persönliche Einstellung wichtig ist. \r\nWie Sie den Kunden richtig betreuen müssen. \r\nWas Standards und Normen in der Servicequalität bewirken. \r\n\r\nBestellen Sie das komplette Hörbuch mit 20 Fragen und Antworten, sowie vielen Zusatzinformationen unter www.ehlers-shop.de	\N
3191	http://www.cardoctorshow.com/rss/rss.xml	Ron Ananian, The Car Doctor	\N	Ron Ananian, The Car Doctor, discusses all aspects of auto repair - from doing it yourself to what your mechanic may or may not be doing correctly to keep your car on the road.	\N
3192	http://feeds.feedburner.com/RobinsonCrusoe	Robinson Crusoe	CandlelightStories.com	Here is 'Robinson Crusoe' by Daniel Defoe in its entirety as a weekly podcast. Widely regarded as marking the start of the english novel, this book is a grand and moving adventure. If your impression of this story comes from a movie, perhaps you should listen. The book is much better. For more audio from CandlelightStories.com, try the Sound Story Club at our web site. You can also listen to a pirate novel at the 'Pirate Jack' podcast.	http://www.candlelightstories.com/images/FairyTaleAudioLogo.jpg
3193	http://twopeasinapodcast.jellycast.com/podcast/feed/2	TWO PEAS IN A PODCAST	twopeasinapodcast	<em>Luke Binns & Tom Boston like puns. Together they are like Two Peas in a Podcast.</em>\n\nAfter the monumental success of series one to five, 'The Peas' are back with a hilarious new series. Join them every week for guaranteed laughs as their ability to get themselves into ridiculous situations and make each other crease with laughter will leave you wanting more every time.\n\nThe new mini series, heavily influenced by the coffee shop routes of series one and two, brings highlights of a weekly Skype conversation. Often absurd, sometimes ridiculous but always entertaining; these boys will have you in stitches every week.\n\nThere are over 80 hysterical episodes to choose from. Whether it's in a coffee shop in series 1 & 2, a radio studio in series 3-5 or in their front rooms 200 miles apart in series 5... These boys will always bring the comedy gold with a constant stream of good old fashioned banter and mucking around.\n\nTwo Peas in a Podcast will make you burst out laughing over and over again. Download this right now. \n\nLike on Facebook: <a href="http://www.facebook.com/twopeasinapodcast">www.facebook.com/twopeasinapodcast</a>\nFollow on Twitter: <a href="http://www.twitter.com/wearethepeas">www.twitter.com/wearethepeas</a>	https://twopeasinapodcast.jellycast.com/files/itunes7.jpg
3194	http://www.avivamiento.com/itunes/deedp.xml	Detras de la Puerta - Audio PodCast	Centro Mundial de Avivamiento	Este podcast contiene las predicas en audio del programa radial Detras de la Puerta del Pastor Ricardo Rodriguez en formato MP3.	http://www.avivamiento.com/itunes/podimage/detras_de_la_puerta.jpg
3195	http://feeds.feedburner.com/photominute	Photo Couch	Gavin Seim & Friends	Tips | Humor | Therapy | 5 minute musings from Gavin Seim. No frills or jingles. Just photo tips, ideas and sometimes very random observations delivered hot and fresh. The little brother of Pro Photo Show. Only for people who are ready to kick back and get informal.	http://prophotoshow.net/content/elements/photo_couch.jpg
3196	http://www.blogtalkradio.com/lifefullcircle.rss	Life Full Circle  w/Miguel Lloyd	Archive	Hosted by Miguel Lloyd <br /><br />Life Full Circle is a show that will feature provocative topics, covering the interests of the full spectrum of its listeners. Current news, entertainment, sports, faith, entrepreneurship, health issues, etc. will all be featured topics of the discussion.	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/27cbe8a2c3c18ba7352a676fc30828cd.jpg
3197	http://folkmedia.libsyn.com/rss	Folk Media	Joel Mark Witt	The Folk Media Show is packed with tips, strategies, and resources to help your organization or business produce, distribute, and promote online media like blogs, audio podcasts, video and Facebook fan pages that will drive sales and promote your products and services on the Internet.\n\nProduced By: Joel Mark Witt	https://ssl-static.libsyn.com/p/assets/7/b/f/3/7bf3cf708bb11f10/FM-New-Square.jpg
3198	http://www.blogtalkradio.com/weupliftradio.rss	Spirits Calling	Archive	Join Aricia Shaffer as she welcomes inspiring celebrities, bestselling authors and experts in the fields of parenting, health, psychology, relationships and home making. <br /><br />Former guests have included Lindsay Wagner, Arun Gandhi, Kathleen DesMaisons, Dr. Ruby Payne and the Whispering Energy Visionary Malathy Drew.<br /><br />If you like the show, please give us a high rating and spread the word to friends, colleagues and families.	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/226e6b74dcfae70e3f3ee790f97ecbe2.jpg
3200	http://www.grind-trax.com/podcast/grx.xml	Grind Trax Radio - Grind Trax Radio	Jun Yagi	You can listen house and techno dj mix on Grind Trax Redio. It is updated first Sunday of each month. Enjoy the Undeground Sound from Tokyo.	http://grind-trax.com/podcast/images/GrindTrax.jpg
3202	http://feeds.soundcloud.com/users/3333011-philderay/tracks	Phil Deray	Philippe Deraymaeker	Podcast by Philippe Deraymaeker	http://i1.sndcdn.com/avatars-000273906592-uarz67-original.jpg
3205	http://www.radioscribe.com/BooknSpade.xml	The Book and The Spade Feed	tdscribe@tds.net (Gordon Govier)	The Book and Spade program has the latest information on discoveries and developments in Biblical Archaeology.	\N
3207	http://www.movieplayer.it/rss/video-recensioni.xml	Le videorecensioni di Movieplayer.it da oggi direttamente sul vostro iPod/iPhone/iPad.	Movieplayer.it	Il Podcast video dedicato alle Videorecensioni di Movieplayer.it. \n            Aggiornato in tempo reale, vi permetterà di ricevere direttamente sul vostro iPod tutte le videorecensioni dei film in uscita nelle sale.	\N
3228	http://www.gaudio.org/lezioni/scrittura/scrittura.xml	Didattica della scrittura	Luigi Gaudio	Lezioni scolastiche del prof. Gaudio sui temi e altre modalità di scrittura	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/3761718ef00b963ee8e0c820b22c6015.jpg
3209	http://feeds.feedburner.com/ElectricChair	Podcast – The Electric Chair	adelphik@gmail.com (Midnight Corey)	The Electric Chair is a horror audio show. Each episode, horror is explored and dissected through interviews with influential people in the horror industry as well as reviews of horror films, literature, and music.	http://electricchairshow.com/images/TheElectricChair-Logo-350x350.jpg
3211	http://site.afterbuzztv.com/cat_shows/teen-wolf-afterbuzz-tv-aftershow/feed/	Teen Wolf Reviews and After Show - AfterBuzz TV	AfterBuzz TV	The Teen Wolf After Show recaps, reviews and discusses episodes of MTV's Teen Wolf.\n\nShow Summary: The high-school anonymity Scott McCall was trying to break free from couldn't have happened in a more mysterious, complicated way. While walking in the woods one night Scott encounters a creature, is bitten in the side, and his life is forever changed. Is he a human or a werewolf? Or a little bit of both? Controlling the strange urges he now feels is the toughest part, and he's afraid the urges could end up controlling him. Will the bite be a gift or a curse, especially as it relates to the mischievous Allison, whom Scott can't get enough of?	https://d3t3ozftmdmh3i.cloudfront.net/production/podcast_uploaded_nologo/1050881/1050881-1537887341314-edff7e0576f23.jpg
3212	http://www.blogtalkradio.com/grammasgarden.rss	Welcome To Gramma's Garden Party Where Nobody Is EVER Told To Sit Down, Shut Up, & Pay Attention!	Archive	Gramma's Garden is now a part of The FlyLady Network. You can still listen to archives here at any time but please go to <a href="http://www.blogtalkradio.com/flylady" rel="noopener">www.blogtalkradio.com/flylady</a> for new shows at 12:30pm EST every Thursday! My topic is ADHD (Attention Deficit Hyperactivity Disorder) in both children and adults.  I hope to offer education about ADHD as well as support for all who live with ADHD on a daily basis.  They will find love and acceptance on my show.	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/111d7868d2dc0fc7e42116222dde4236.jpg
3213	http://acealvarez.podomatic.com/rss2.xml	Ace Alvarez -NYC Abduction Podcast	Ace Alvarez	The NYC Abduction Podcast With Ace Alvarez	https://assets.podomatic.net/ts/44/5d/53/acealvareznyc/3000x3000-732x732+801+4_8346700.jpg
3214	http://feeds.feedburner.com/Blackrock	Black Rock LOST Podcast	Curt & Dan	Fan based podcast about ABC?s hit TV show LOST with more theories and less rehash.. We will put forward our theories about the islands mysteries, the DHARMA Initiative, Hanso Foundation while exploring interesting theories we find in the forums. These are enhanced podcasts which include photo?s throughout the episode. For MP3 versions of the show please visit the Lost Podcasting Network. For forums and full fledged LOST community look for us at theblackrock.org	http://creativecommons.org/images/public/somerights20.gif
3216	http://www.jean-luc-melenchon.fr/feed/podcast/	Les Blogcasts de Jean-Luc Mélenchon	Le Blog de Jean-Luc Mélenchon	Jean-Luc Mélenchon perpétue une tradition de grands tribuns de gauche. Son talent d'orateur lors de discours en meeting, lors de débats ou d'émissions télévisées, est reconnu. Le fil i-tunes des "Blogcasts de Jean-Luc Mélenchon" permet de découvrir ou de réécouter ses discours et interventions, en les téléchargeant sur un balladeur mp3 ou en se connectant sur la borne i-tunes depuis un ordinateur.	http://www.jean-luc-melenchon.fr/imgs/powered_by_podpress_large.jpg
3217	http://feeds.feedburner.com/TOS_Interviews	Taste of Sex - Guest Speaker: Visiting Guest Speaker Interviews	Personal Life Media	OneTaste (onetaste.us), a leading educational organization  in the field of relationships, intimacy and mindful sexuality offers a lecture  series of wide ranging interest &ndash; from leadership and purpose to music,  spirituality and sexuality. Join Professor Jorge Ferrer of the California Institute  of Integral Studies in an exploration of the intersection between sex and  spirit; or folk musician, Jennifer Berezan, as she opens to music and the  sacred.&nbsp; Meet environmental pioneer Ocean  Robbins as he delves deep into the important issues facing young people and  explores possible solutions to our pressing environmental issues. Discover new  forms of leadership and governance in Eric Grahm&rsquo;s discussion of Holacracy. And  awaken a deeper joy in life with Buddhist teacher James Baraz.&nbsp; Over 50 interviews to stretch your spirit,  mind and imagination.	http://assets.personallifemedia.com/images/albums/rss_TSGS.jpg
3218	http://inspirationalpodcast.podomatic.com/rss2.xml	Kris Gilbertson l Millionaire & Expert Interviews / Business l Marketing l Mindset l Inspirational Podcast	KrisGilbertson.com	Experts Agree that the Best and Fastest way to success is to emulate what already successful people do. This is exactly what we unveil on this inspirational podcast through Expert & Millionaire Interviews help you explode your success and create a the lifestyle you're dreaming about! To learn how to drive more traffic to your website, double your email opt-in rate, and easily increase sales in your business and create passive income, make sure to subscribe @ www.krisgilbertson.com for Free multi-media marketing updates to help you in your business!	https://assets.podomatic.net/ts/76/bb/0c/realsolutionstoday87091/3000x3000_8233677.jpg
3219	http://golftalkradiomikeandbilly.libsyn.com/rss	Golf Talk Radio with Mike & Billy Podcasts	Mike Brabene, PGA & Billy Gibbs, PGA	Golf Talk Radio with Mike & Billy airs every Saturday from 8:05am to 10:00am PST California time in San Luis Obispo, California on ESPN 1280am and on ESPN 1230am in Bakersfield/Kern County.  Listen to GTR LIVE over the internet from any where in the world at www.espnradio1280.com.  Mike and Billy are PGA Professionals with over 50 years of experience in all aspects of the golf industry from teaching to management.  Every week Mike & Billy focus on the lighter side of golf, golf instruction, golf trivia and interview people in the industry.  For more information on the show check out the Golf Talk Radio with Mike & Billy website at www.golftalkradio.com.	https://ssl-static.libsyn.com/p/assets/5/d/d/1/5dd126963a0f78d8/Golf_Talk_Radio_Logo1400.jpg
3220	http://feeds.feedburner.com/yeahitsthatbad	Dead Air	Yeah, It's That Bad	A movie podcast that reviews movies that are considered to be awful remakes, box office bombs, useless sequels and other critically hated films, and we ask the question: "is it really that bad"?	http://i1220.photobucket.com/albums/dd454/yeahitsthatbad/YITB_Logo_1400x1400.jpg
3221	http://mrlister.podOmatic.com/rss2.xml	rob f's Podcast	rob f		https://mrlister.podomatic.com/images/default/podcast-4-3000.png
3224	http://www.poderato.com/pieladentro/_feed/1	C desnuda la Piel - Podcast (Podcast) - www.poderato.com/pieladentro	www.podErato.com	Una charla entre amigos, un sitio de intimidad, ideal para compartir poesía de los consagrados, de los amigos bloguers y escritores ademas de los escritos por mi, como un plus los número par (a partir del 14) dedicados a temas sexuales, (Los favoritos de Pieladentro), ¡Bienvenidos!	http://www.poderato.com/files/images/15299l8451lpd_lrg_player.jpg
3227	http://bruins.nhl.com/podcasts/bruinscast.xml	BruinsCast	Bruins Cast	The official podcast of the Boston Bruins	http://bruins.nhl.com/v2/ext/images/SpokedB_wHeadphones200.jpg
3232	http://www.ntv.ru/exp/ipromo.jsp	Телепрограмма НТВ	NTV.ru	Самый известный российский телеканал НТВ представляет видеоподкаст! Последнее промо телеканала! The most well-known Russian TV channel NTV presents videopodcast. Up-to-the-minute promo sujets!	http://www.ntv.ru/exp/ntv_new.jpg
3233	http://www.mercypca.org/feed/podcast/	Mercy Church	bdriedel@comcast.net (Mercy Church (PCA))	Weekly sermon audio from Mercy Church (PCA) in Morgantown, WV.	http://www.mercypca.org/wp-content/images/iTunesimage.png
3235	http://site.afterbuzztv.com/cat_shows/boardwalk-empire-afterbuzz-tv-aftershow/feed/	Boardwalk Empire Reviews and After Show - AfterBuzz TV	AfterBuzz TV	The Boardwalk Empire After Show recaps, reviews and discusses episodes of HBO's Boardwalk Empire.\n\nShow Summary: Boardwalk Empire is a period drama focusing on Enoch "Nucky" Thompson (based on the historical Enoch L. Johnson), a political figure who rose to prominence and controlled Atlantic City, New Jersey, during the Prohibition period of the 1920s and 1930s. Nucky acts with historical characters in both his personal and political life, including mobsters, politicians, government agents, and the common folk who look up to him. The federal government also takes an interest in the bootlegging and other illegal activities in the area, sending agents to investigate possible mob connections but also looking at Nucky's lifestyle—expensive and lavish for a county political figure. The final season jumps ahead seven years, to 1931, as Prohibition nears its end.	https://d3t3ozftmdmh3i.cloudfront.net/production/podcast_uploaded_nologo/1050602/1050602-1537889535179-1b80a93e76ab8.jpg
3236	http://www1.swr.de/podcast/xml/swr2/wort-zum-tag.xml	SWR2 Wort zum Tag - Kirche im SWR	Kirche im SWR	SWR2 Wort zum Tag	https://www.kirche-im-swr.de/custom/img/podcast_cover/wort-zum-tag.jpg
3237	http://downloads.bbc.co.uk/podcasts/fivelive/5lfd/rss.xml	Football Daily	BBC	The latest from the Premier League, EFL, European football and more!	http://ichef.bbci.co.uk/images/ic/3000x3000/p07gdh59.jpg
3239	http://feeds.soundcloud.com/users/39719194-green-and-gold-rugby/tracks	Green And Gold Rugby	Green And Gold Rugby	Podcast channel for THE Aussie Rugby Website: Gre…	http://i1.sndcdn.com/avatars-000047685807-qp1pcp-original.png
3240	http://urotrosfiles.media.streamtheworld.com/otrosfiles/podcasts/365.xml	Anda Ya | LOS40	LOS40	Escucha los mejores momentos del programa despertador más escuchado	http://los40.com/tag/includes/imagenes/Podcast_AndaYa.jpg
3248	http://feeds.feedburner.com/SuvuduOnAir	Suvudu On Air	Suvudu	A podcast covering all things Science Fiction, Fantasy, Comics, and Gaming! Check us out on iTunes or whereever fine podcasts are stored.	http://www.suvudu.com/On-Air_100.gif
3251	http://feeds.feedburner.com/cnet/cartechvideohd	Roadshow Reviews (HD)	CNETTV (stephen.beacham@cbsi.com)	Hop in the passenger seat and ride along with Roadshow editors as we put each car through its paces, analyzing the tech, the performance and the design to see whether it’s worth your hard-earned money.	https://cnet4.cbsistatic.com/hub/i/2016/05/10/df63a34e-cbc6-4e21-85fe-83846ed2dd8d/roadshowreviews300x300.jpg
3252	http://massp.libsyn.com/rss	MASSP Podcast	Chelsey Martinez	The Michigan Association of Secondary School Principals advances learning through educational leadership.\n\nFor more information, check out our website: mymassp.com and follow us on Twitter @MASSP	https://ssl-static.libsyn.com/p/assets/8/5/3/4/8534ee752e3a8ce5/MASSP_Podcast_Logo-FOR_ITUNES.jpg
3253	http://feeds.feedburner.com/DrUsamaAl-atarLectures	Dr. Usama Al-Atar Lectures	ShiaEdmonton.com	Al-Hajj Usama Al-Atar is originally from the holy city of Karbala. He is well rounded at the academic level, and he is very active at the religious level as well. This podcast serves to distribute all his lectures from different places he has visited and spoken at.	http://images.ctv.ca/archives/CTVNews/img2/20111030/470_usama_al_attar_111030.jpg
3255	http://farnsworthke.podOmatic.com/rss2.xml	farnsworthke's Podcast	Ken Farnsworth		https://farnsworthke.podomatic.com/images/default/podcast-4-1400.png
3256	http://galacticwatercooler.com/category/all-podcasts/modern-geek-podcast/feed/	Modern Geek	chuck@galacticwatercooler.com (GWC Network)	We live the geek lifestyle, and in this podcast we share it with you every week, discussing current news, fun projects, and cool products -- all from a geek perspective.	http://galacticwatercooler.com/wp-content/uploads/powerpress/modern-geek-144-144.jpg
3259	http://www.sunsetcast.com/podcast.asp?cUserIdx=AB4JRYD15KSW6APCS&ihpodcodex=33&cFilnamex=33AB4JRYD15KSW6APCS.xml	SunsetCast - eToons	SunsetCast	SunsetCast Media System International is a leading distributor of independent, foreign, and classic films. This podcast will post a new film, clip, or trailer on a recurring basis. Clips may be viewed freely, but may not be sold, redistributed, or used for public exhibition.	https://www.sunsetcast.com/podpict/podcast33.jpg
3262	http://promodj.com/djshishkin/rss.xml	DJ Shishkin	PromoDJ (Djshishkin@gmail.com)	DJ SHISHKIN – Один из самых успешных московских ди-джеев и саунд-продюсеров. \n Учредитель лейбла CASA Production Ltd. \n Автор и продюсер более чем сотни успешных релизов на огромном количестве мировых лейблов, в числе которых : Nitron Music (Sony Music), VANDIT (NL), EGO (ITL), Housesession Records (DE), PACHA Records (SP), Caballero Recordings (DE), Recovery Music, Baccara Records, Lickin Records (DE), SUKA Records (FR), Diamondhouse Records...	https://cdn.promodj.com/afs/295a1f6d25b7b754c40759a9e9275a3d:resize:1400x1400:same:074884.png
3265	http://feeds.feedburner.com/ChurchOfTheEpiphany-Homilies	Homilies	Epiphany Catholic Church	Weekly liturgy homilies	https://epiphanycatholicchurch.org/_media/podcasts/Podcast-Thumbnail-for-iTunes.jpg
3269	http://feeds.feedburner.com/ATravesDelUniverso	A Través del Universo	universo@iaa.es	Podcast que contiene los programas de divulgación astrofísica y astronómica A Través del Universo, del Instituto de Astrofísica de Andalucía. Presentado por Emilio García y Pablo Santos.	https://juandesant.files.wordpress.com/2018/01/itunesatu.jpg
3272	http://podcast.rthk.org.hk/podcast/june04.xml	香港電台︰「六四」系列《走過二十年》	RTHK.HK	二十年前，北京一場爭取民主的運動，以悲劇收場，每年六月四日，都會有人悼念這一天。\n\n二十年後的今天，香港電台新聞部製作一系列「走過二十年」特輯，訪問現時仍在海外的學運參與者、協助民運人士逃抵香港的「黃雀行動」負責人，以及根據前總書記趙紫陽秘密錄音出版書籍的鮑樸等。	http://podcast.rthk.hk/podcast/upload_photo/item_photo/1400x1400_196.jpg
3273	http://feeds.feedburner.com/wxxi-artsfriday	1370 Connection: Arts Friday	WXXI Public Broadcasting Council (podcasts@wxxi.org)	Arts Friday is a monthly show offered as part of the daily 1370 Connection call-in program that deals with Rochester Area Arts & Culture topics.	http://wxxi.org/talk1370/images/1370connection_logo200.jpg
3274	http://kathasansar.podomatic.com/rss2.xml	कथा संसार KATHA SANSAR	Katha Sansar	This is complete audio Collection of Nepali Stories.This is an another presentation Of  Himali Swarharu..an online Nepali radio http://www.nepaliradionyc.com\nकथा  र सृजनाहरू आवाज मार्फ़त ! कथाहरु लेखेर भन्दा भावानात्मक स्वरमा सुनाउने अभियान. आफ्नो कथा भावना लाइ यस्तै आवाज मार्फ़त आफ्ना पाठकहरुलाई सुनाउने हो भने कथा कबिता पठाउनु होस...हामी आवाज दिने छौ....\nContact Us:nepaliradio@gmail.com\nVisit Us:www.nepaliradionyc.com	https://assets.podomatic.net/ts/13/b7/3d/kathasansar/3000x3000_729733.jpg
3275	http://recordings.talkshoe.com/rss65306.xml	The Larry Love Show	shinetop	Larry Michel, AKA "The Love Shepherd" interviews the world's most influential and transformative thought leaders and teachers in the area of love and relationships. Larry Michel also reveals the energetic third dimension to relationships. Without this energetic element the quality of all relationships is the result of luck and guesswork. Now there is guidance for true relationship stability and fulfillment. Listen to Larry Michel every week as you get the KEY to a successful relationship.	https://show-profile-images.s3.amazonaws.com/production/1408/the-larry-love-show_1531860961_itunes.png
3278	http://djvinylvera.podOmatic.com/rss2.xml	DJ Vinyl Vera-In The Mix	Vinyl Vera	Female DJ from the UK. DJ-ing since 1998. Vinyl Only!!!!	https://assets.podomatic.net/ts/f2/25/d3/djvinylvera/3000x3000_5061146.jpg
3280	http://www.skeptiko.com/feed/	Skeptiko – Science at the Tipping Point	alex@skeptiko.com (Alex Tsakiris)	About the Show<br />\nSkeptiko.com is an interview-centered podcast covering the science of human consciousness. We cover six main categories:<br />\n– Near-death experience science and the ever growing body of peer-reviewed research surrounding it.<br />\n– Parapsychology and science that defies our current understanding of consciousness.<br />\n– Consciousness research and the ever expanding scientific understanding of who we are.<br />\n– Spirituality and the implications of new scientific discoveries to our understanding of it.<br />\n– Others and the strangeness of close encounters.<br />\n– Skepticism and what we should make of the “Skeptics”.	https://skeptiko.com/wp-content/uploads/powerpress/itunes-skeptiko-1400.jpg
3282	http://www.blogtalkradio.com/i-just-finished.rss	Coffee with an Author	Archive	"Coffee with an Author" Ijustfinished.com's weekly podcast interviewing authors about their writing styles, works, goals, and dreams. Join Naomi Giroux, host of Coffee with an Author by calling in (646-716-9724), joining the chat room or by visiting the ijustfinished website with questions/comments. Don't forget to rate our shows. Visit with us weekly!<br /><br />"Best Sellers' Club" a weekly program interviewing Best Selling Authors. Call in, join the chat room or follow us on Twitter. More information at ijustfinished.com<br /><br />"WriteOn!" the monthly round table discussion by experts in areas of interest to writers.<br /><br />If you'd like to be a guest contact Booklover at ijustfinished.com	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/ea7f8056e49fefe7433c1b5f32a5dee2.jpg
3287	http://logicandsence.podbean.com/feed/	Logic and Sense	Ty Kelly and Tristan Font	Each Week Tk and Dark Wolf Disscuss A Controversial Topic With Logical and Sensable Points	https://pbcdn1.podbean.com/imglogo/image-logo/520995/LANDS.png
3288	http://podcast.rthk.org.hk/podcast/noveltoday.xml	香港電台︰今天聽小說	RTHK.HK	文學作品除了可以讀，也可以聽。「今天聽小說」就是將文字化作聲音，傳送到聽眾的耳邊。節目揀選了多篇精彩的短篇小說，其中包括名作家白先勇、三毛、亦舒、李碧華及林燕妮等之作品。兩位資深的播音藝員：焦姣及張妙陽，用悅耳的聲線及豐富的感情，演譯多篇名家作品，使作品的神髓更活靈活現。（本節目全部以普通話/國語播出，編導:張建浩）	http://podcast.rthk.hk/podcast/upload_photo/item_photo/1400x1400_203.jpg
3289	http://www.meanderingmouse.com/rss.xml	Meandering Mouse and Meandering Mouse Club TV-(AUDIO and VIDEO) Disney Park Fun	Disney Fan: Jeff from Houston (podcast@meanderingmouse.com)	Nominated for Best Travel Podcast 2007 and a featured travel podcast in iTunes since 2005! Join Disney theme park enthusiast and your host, Jeff from Houston, on his adventures and mis-adventures at the Disney resorts throughout the WORLD on The Meandering Mouse podcast. The Meandering Mouse audio podcast is a personable take on Disney attractions both large and small including quality stereo audio recorded live in the parks, unique commentary, interesting facts on past attractions, and the occasional wacky surprise. Meandering Mouse Club TV is you chance to take visual adventures throughout ALL the DIsney parks around the globe.  Entire coverage of Hong Kong, Tokyo, and Paris will be featured.  At the Meandering Mouse Podcast your hosts don't borrow audio from overseas; we go there and share the fun with you through the magic of audio and video.  The Meandering Mouse founded and hosts The Disney Podcast Network.  MMCTV is produced in association with Frikitiki Productions.	http://www.meanderingmouse.com/images/TMM144.jpg
3290	http://media.aspireone.com/mediaplayer/cedarcreek/audioPodcast.aspx?id=709	CedarCreek Audio Podcast	CedarCreek Church (admin@cedarcreek.tv)	No matter who you are, where you’re from, or what you believe – You matter to God, you matter to us, and you’re welcome here.\n\nOur dream is to see our communities completely transformed. We believe that happens one individual at a time. When an individual is transformed, they can’t help but make a positive and lasting impact in their community. When you allow God to transform you, it will transform the people around you.\n\nJoin us as we introduce people to Jesus and the life changing adventure with him.\n\nhttps://cedarcreek.tv	https://images.subsplash.com/base64/L2ltYWdlLmpwZz9pZD1lNTE1YzZlYS1lYWU3LTQ5MTgtYTlhOC0yMDFmMTIyMDhlZTEmdz0xNDAwJmg9MTQwMA.jpg
3291	http://www.blogtalkradio.com/cl.rss	Radio Bedroom Lounge & Chat	Archive	Cory Live, a host that is truly #1 in the business of what he does, brings the best relationship advice, comedy, and simply, the besttopics during the free discussions, that any host could ever bring.<br /><br />Hosted by Cory Legendre, Cory Live's Radio Bedroom is a true let-loose and anything-goes place. That's why it's so cool to just come chill with the great people that make the show go on each and every night.<br /><br />Call-ins are always welcome, and are encourages, especially during free discussions and contests.<br /><br />Especially now that we've all kicked it up as the new Radio Bedroom Lounge and Chat, you're sure to have fun with us!	https://d3wo5wojvuv7l.cloudfront.net/t_rss_itunes_square_1400/images.spreaker.com/original/640ad6741b943448027b3868f8a0f555.jpg
3294	http://feeds.feedburner.com/AmateurTravelerVideo	Amateur Traveler Video (small) | travel for the love of it	Chris Christensen	A video travel podcast for people who love to travel. It can be viewed as a companion to the Amateur Traveler audio podcast or on its own. It features narrated travelogs.	http://static.libsyn.com/p/assets/c/b/b/2/cbb22b1531f46c6f/AmateurTraveler-video-1400x1400.png
3295	http://sports.espn.go.com/espnradio/podcast/feeds/itunes/podCast?id=2445552	Keyshawn, JWill & Zubin	ESPN	Every morning, former #1 pick in the NFL Draft, Keyshawn Johnson, joins former #2 pick in the NBA, Jay Williams, alongside SportsCenter anchor Zubin Mehenti as they set the table for the day. From the games that electrified us the night before, to the stories that will captivate all day long, the trio of Key, JWill and Z will update, inform and entertain. They’ll be joined by the most respected experts in all of sports to break down what really matters. This is the home for hourly podcasts of the show.	https://images.megaphone.fm/G69d5h4sSpoK3-mIsU1vc0DXUYId4MqPmUzYiKGqIpM/plain/s3://megaphone-prod/podcasts/a67e83fc-d101-11ea-b0fe-37aeac80ca38/image/3000_20200810134301.jpg
3296	http://rss.dw-world.de/xml/podcast_living-planet	Living Planet | Deutsche Welle	DW.COM | Deutsche Welle	Every Thursday, a new episode of Living Planet brings you environment stories from around the world, digging deeper into topics that touch our lives every day. The prize-winning, weekly half-hour radio magazine and podcast is produced by Deutsche Welle, Germany's international broadcaster - visit dw.com/environment for more.	https://static.dw.com/image/2266720_7.jpg
3299	http://feeds.feedburner.com/pcp2	pcp{2}	Pete Cogle (pete.cogle@gmail.com)	More eclectic music from Pete Cogle, host of PC Podcast and The Dub Zone.	http://pcp2.blogsome.com/images/pcp2_square.jpg
\.


--
-- Data for Name: rejectedrecommendations; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.rejectedrecommendations (userid, podcastid) FROM stdin;
\.


--
-- Data for Name: searchqueries; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.searchqueries (userid, query, searchdate) FROM stdin;
25	something	2005-01-30 05:05:05
25	something	2010-01-30 05:05:05
25	something	2020-01-30 05:05:05
25	Hello Internet	2020-04-20 05:05:05
25	hello	2020-10-25 23:59:39.322948
25	hello	2020-10-25 23:59:55.141266
25	hello	2020-10-26 00:00:49
25	hello	2020-10-26 00:04:24
25	Delearte	2020-10-28 10:56:00
\.


--
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.subscriptions (userid, podcastid) FROM stdin;
2	1
2	2
2	3
2	6
2	4
3	1
3	2
3	6
4	4
4	2
4	6
5	3
5	4
25	1
25	249
\.


--
-- Data for Name: test; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.test (a, b, c) FROM stdin;
1	testing	2020-01-01
2	yo	\N
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: brojogan
--

COPY public.users (id, username, email, hashedpassword) FROM stdin;
2	tom	tom@example.com	$2b$12$vo5q.Bpwl5myC3qTww44EOrqYVE1qZTCM1oJIhhFb6Vq8X0U2KTCm
3	pawanjot	pawanjot@example.com	$2b$12$mEXlUC8n0wJH8blt26KeVujn4aga3NJX7RV4M9Vx3yrPJu3YlV8rW
4	justin	justing@example.com	$2b$12$b0QdZw3lLRjUI3nTKnmNyu5OUTvmjZb1eIvo9hdVbzY1G8Nxgx75y
5	nich	nich@example.com	$2b$12$SfoSQ3Pq1vt24QKHtsCIWONJ39C9W1/yWJWclAA8Y43aMldi1q1Jq
6	michael	mc@example.com	$2b$12$HGJribFoHIx53aCxqkr1I.efHZfYfpx44zk59huIWQ.mfWMh/z75K
7	something	something@something.com	$2b$12$6OtjaivEtb4H7W2AqemTJ.mKX8RYl/VkKv0VV18uyz4skmKp23avu
8	justin2	justin2@email.com	$2b$12$46EyzBXvDAcrS04zirDlfOb9yRUhzTmWgczQLEejCq4CEWr54rO/.
9	beepboop	beepboop@hotmail.com	$2b$12$kTTiMB/Y/D4iWo6I9FisuON0oFvBzCC8TBw9MMtrRz8OkmWq47USe
10	testaccount	testaccount@gmail.com	$2b$12$ayj42yg7A5tHo57NLLk54ev5OfTMHKtw8cmI8NIiaoRSLjAlowLt2
11	accounttest	accounttest@hotmail.com	$2b$12$Hiwt/KLXQwI/4e2.kJzCkucxxBtVmkdDs0KLsVVD/b9V73zHBzZEa
12	justin5	justin5@email.com	$2b$12$yhv3TcQpjOSp7yDKPF0CqOO2yPhYts.NcxF2eKJ.lq.OyW9Ekv1am
13	hellohello	hellohello@hotmail.com	$2b$12$8u51XOZz39nevcoCoroDSehoLqo4gdVXmFrjM09o3bkP4BOZSyObq
15	justin100	justin100@email.com	$2b$12$zXJj2ab.OnYLUlZPV10Aj.zY6GGRq0ZiS2jzAoBZY5mbfN8ZZtX1u
17	justin1000	justin1000@email.com	$2b$12$uAcxGbquLPL9YfN0DjuwHeM/4apCXELNIdXki4tKRyjWbHcpxpfrm
18	justin20	justin20@email.com	$2b$12$WOgaLjYtYlg5ecyEWnwqKuex7doGNDCdoOMS4ScWjU.0uT6Jr6aRG
19	justin2000	justin2000@email.com	$2b$12$XZ/bOLhs8J4jhH1Q9bRt2uddpzim/5x7DvOR52cbm5RrFITh6sk76
20	justin5000	justin5000@email.com	$2b$12$E7mDhdGppchgx/UhoR8wOOoJeOpJYqetY2jShJlPKXU45aKnpF8Se
21	something4	some3@thing.com	$2b$12$jvqHlUj4z1BnK73Sr4wrwukDZzMBFyXjvQYfbywyYgxBceJfsKkxa
14	justin50	currentemail@a.c	\\x24326224313224693867656f35515139376261617a67734f684d56382e71774e6a674c764e335834704e2e77764a30313864436a56676f5764303961
25	something123	s@s1.com	$2b$12$AfS24/5CWJM0jpkQm6LJRutuKU6racYmK47/FpTOJdxWakLPVDusm
28	justin60	justin50@email.com	$2b$12$4iOR6S9UNSdeWszzkgOIUu/ubnAfgNTgsXYzTkYSBl.5AnvXlSKwi
\.


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: brojogan
--

SELECT pg_catalog.setval('public.categories_id_seq', 754, true);


--
-- Name: podcasts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: brojogan
--

SELECT pg_catalog.setval('public.podcasts_id_seq', 3408, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: brojogan
--

SELECT pg_catalog.setval('public.users_id_seq', 28, true);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: episoderatings episoderatings_pkey; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.episoderatings
    ADD CONSTRAINT episoderatings_pkey PRIMARY KEY (userid, podcastid, episodeguid);


--
-- Name: episodes episodes_guid_key; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT episodes_guid_key UNIQUE (guid);


--
-- Name: episodes episodes_pkey; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT episodes_pkey PRIMARY KEY (podcastid, guid);


--
-- Name: listens listens_pkey; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.listens
    ADD CONSTRAINT listens_pkey PRIMARY KEY (userid, podcastid, episodeguid);


--
-- Name: podcastcategories podcastcategories_pkey; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.podcastcategories
    ADD CONSTRAINT podcastcategories_pkey PRIMARY KEY (podcastid, categoryid);


--
-- Name: podcastratings podcastratings_pkey; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.podcastratings
    ADD CONSTRAINT podcastratings_pkey PRIMARY KEY (userid, podcastid);


--
-- Name: podcasts podcasts_pkey; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.podcasts
    ADD CONSTRAINT podcasts_pkey PRIMARY KEY (id);


--
-- Name: podcasts podcasts_rssfeed_key; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.podcasts
    ADD CONSTRAINT podcasts_rssfeed_key UNIQUE (rssfeed);


--
-- Name: rejectedrecommendations rejectedrecommendations_pkey; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.rejectedrecommendations
    ADD CONSTRAINT rejectedrecommendations_pkey PRIMARY KEY (userid, podcastid);


--
-- Name: searchqueries searchqueries_pkey; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.searchqueries
    ADD CONSTRAINT searchqueries_pkey PRIMARY KEY (userid, query, searchdate);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (userid, podcastid);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: categories categories_parentcategory_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_parentcategory_fkey FOREIGN KEY (parentcategory) REFERENCES public.categories(id);


--
-- Name: episoderatings episoderatings_podcastid_episodeguid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.episoderatings
    ADD CONSTRAINT episoderatings_podcastid_episodeguid_fkey FOREIGN KEY (podcastid, episodeguid) REFERENCES public.episodes(podcastid, guid);


--
-- Name: episoderatings episoderatings_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.episoderatings
    ADD CONSTRAINT episoderatings_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(id);


--
-- Name: episodes episodes_podcastid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.episodes
    ADD CONSTRAINT episodes_podcastid_fkey FOREIGN KEY (podcastid) REFERENCES public.podcasts(id);


--
-- Name: listens listens_podcastid_episodeguid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.listens
    ADD CONSTRAINT listens_podcastid_episodeguid_fkey FOREIGN KEY (podcastid, episodeguid) REFERENCES public.episodes(podcastid, guid);


--
-- Name: listens listens_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.listens
    ADD CONSTRAINT listens_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(id);


--
-- Name: podcastcategories podcastcategories_categoryid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.podcastcategories
    ADD CONSTRAINT podcastcategories_categoryid_fkey FOREIGN KEY (categoryid) REFERENCES public.categories(id);


--
-- Name: podcastcategories podcastcategories_podcastid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.podcastcategories
    ADD CONSTRAINT podcastcategories_podcastid_fkey FOREIGN KEY (podcastid) REFERENCES public.podcasts(id);


--
-- Name: podcastratings podcastratings_podcastid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.podcastratings
    ADD CONSTRAINT podcastratings_podcastid_fkey FOREIGN KEY (podcastid) REFERENCES public.podcasts(id);


--
-- Name: podcastratings podcastratings_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.podcastratings
    ADD CONSTRAINT podcastratings_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(id);


--
-- Name: rejectedrecommendations rejectedrecommendations_podcastid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.rejectedrecommendations
    ADD CONSTRAINT rejectedrecommendations_podcastid_fkey FOREIGN KEY (podcastid) REFERENCES public.podcasts(id);


--
-- Name: rejectedrecommendations rejectedrecommendations_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.rejectedrecommendations
    ADD CONSTRAINT rejectedrecommendations_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(id);


--
-- Name: searchqueries searchqueries_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.searchqueries
    ADD CONSTRAINT searchqueries_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(id);


--
-- Name: subscriptions subscriptions_podcastid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_podcastid_fkey FOREIGN KEY (podcastid) REFERENCES public.podcasts(id);


--
-- Name: subscriptions subscriptions_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: brojogan
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_userid_fkey FOREIGN KEY (userid) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

