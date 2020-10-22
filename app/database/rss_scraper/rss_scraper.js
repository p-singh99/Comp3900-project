const Parser = require('rss-parser');
const readline = require('readline');
const { Pool, Client } = require('pg');

const client = new Client({
    user: 'brojogan',
    host: 'polybius.bowdens.me',
    database: 'ultracast',
    password: 'GbB8j6Op',
    port: 5432
});

let count=0;
const parser = new Parser();
let rl;

client.connect(err => {
    if (err) {
        console.log("connection error");
    } else {
        console.log("database ready");
        rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });

        rl.on('close', () => {
            console.log("done reading; there will be more async resquests tho");

        });
        rl.on('line', (url) => {
            async function foo() {
                let podcastid = -1;
                console.log(" -- reading url '" + url + "'");
                let feed;
                try {
                    feed = await parser.parseURL(url);
                } catch (error) {
                    console.error("there was an error reading the rss feed " + url + ". continuing");
                    console.error(error);
                    return;
                }
                console.log("   -- got feed for url '" + url + "'");
                try {
                    let res = await client.query("insert into podcasts (rssfeed, title, author, description, thumbnail) values ($1, $2, $3, $4, $5) returning id",
                                 [url, feed.title, feed.itunes ? feed.itunes.author : null, feed.description, feed.itunes ? feed.itunes.image : null]
                                );
                    if (res.rowCount != 1) {
                        console.error("    -- something went wrong inserting into podcasts:");
                        console.error(res);
                    } else {
                        //console.log("   -- added url '" + url + "'");
                        podcastid = res.rows[0].id;
                    }
                } catch (error) {
                    console.error("    -- there was an error inserting");
                    console.error(error);
                    return;
                }
                let categories = [];
                if (feed.itunes) {
                    categories = feed.itunes.categories;
                    //console.log("    -- categories are:");
                    //console.log(categories);
                    try {
                        for (let a of categories) {}
                    } catch (error) {
                        console.error("error iterating: ");
                        console.error(error);
                    }
                }
                console.log(" for " + url + " categories is " + categories);
                for (let category of categories) {
                    try {
                        let res = await client.query("select * from categories where name = $1",
                                                     [category]
                                                    );
                        //console.log(category);
                        let categoryid;
                        if (res.rowCount == 0) {
                            try {
                                let newres = await client.query("insert into categories (name) values ($1) returning id",
                                                            [category]
                                                           );
                                //console.log("after inserting new category newres is");
                                //console.log(newres);
                                //console.log("newres.rows: " + newres.rows);
                                //console.log("newres.rows[0]: " + newres.rows[0]);
                                //console.log("newres.rows[0].id: " + newres.rows[0].id);

                                categoryid = newres.rows[0].id;
                            } catch (error) {
                                console.error("    -- something went wrong inserting the new category");
                                console.error(error);
                            }
                        } else {
                            //console.log("after selecting category, res is");
                            //console.log(res);
                            //console.log("res.rows: " + res.rows);
                            //console.log("res.rows[0]: " + res.rows[0]);
                            //console.log("res.rows[0].id: " + res.rows[0].id);
                            categoryid = res.rows[0].id;
                        }
                        try {
                            let newres = await client.query("insert into podcastCategories (podcastId, categoryId) values ($1, $2)",
                                                           [podcastid, categoryid]);
                        } catch (error) {
                            console.error("    -- something went wrong inserting the new podcast category");
                            console.error("      -- podcastid was " + podcastid + ", categoryid was " + categoryid);
                            console.error(error);
                            return;
                        }
                    } catch (error) {
                        console.error("    -- there was an error checking the categories");
                        return;
                    }
                }
            }
            count += 1;
            console.log("count: " + count);
            foo();
        });
    }
});

