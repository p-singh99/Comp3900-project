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
            client.end()
            process.exit(0);
        });

        rl.on('line', (url) => {
            async function foo() {
                console.log(" -- reading url '" + url + "'");
                let feed = await parser.parseURL(url);
                console.log("   -- got feed for url '" + url + "'");
                let res = await client.query("insert into podcasts values (default, $1, $2, $3, $4, $5)",
                             [url, feed.title, feed.itunes ? feed.itunes.author : null, feed.description, feed.itunes ? feed.itunes.image : null]
                            );
                if (res.rowcount != 1) {
                    console.log("something went wrong:");
                    console.log(res);
                } else {
                    console.log("added url '" + url + "'");
                }
            }
            foo();
        });
    }
});

