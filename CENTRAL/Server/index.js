const express = require("express");
const udp = require("dgram");
const bodyparser = require("body-parser");

const srvUDP = udp.createSocket('udp4');
const srvHTTP = new express();

let CLIENTS = [];

let tableIP = [];

setInterval(()=>{
    CLIENTS = [];
    tableIP = [];
}, 30000);

srvUDP.on('message', (msg, rinfo) => {
    let msgJSON = JSON.parse(msg.toString());

    if (!CLIENTS.includes(msgJSON)) {
        CLIENTS.forEach((client, idx) => {
            if (client.id == msgJSON.id) {
                CLIENTS.splice(idx, 1);
                tableIP.splice(idx, 1);
            }
        });

        CLIENTS.push(msgJSON);
        tableIP.push(rinfo.address);
    }

})
    .bind(85);

srvHTTP
    .use(bodyparser.urlencoded({ extended: true }))

    .get("/", (req, res) => {
        res.send(CLIENTS);
    })

    .post("/command", (req, res) => {
        let msgJSON = JSON.parse(req.body.command.toString());
        let sended = false;

        CLIENTS.forEach((client, idx) => {
            
            if (client.id == msgJSON.id) {
                console.log(JSON.stringify(msgJSON));
                srvUDP.send(JSON.stringify(msgJSON), 85, tableIP[idx]);
                res.send("ok");
                sended = true;
            }
        });

        if (!sended) {
            res.send("Error");
        }

        if(msgJSON.key == "id"){
            CLIENTS = [];
            tableIP = [];
        }
    })

    .listen(85);
