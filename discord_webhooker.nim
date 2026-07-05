import std/[httpclient, json, strutils, nativesockets, sugar, sequtils]
import mummy, mummy/routers
#import dotenv

#dotenv.load()

const
  DISCORD_WEBHOOK_URL {.strdefine.} = ""
  PORT {.intdefine.}: uint16 = 50007

if DISCORD_WEBHOOK_URL == "":
  echo "Please set -d:DISCORD_WEBHOOK_URL during `nim c`."
  quit 1


proc github_terra(request: Request) {.gcsafe.} =
  var headers: httpheaders.HttpHeaders
  headers["Content-Type"] = "text/plain"
  let payload = request.body.parseJson
  echo request.headers["X-Github-Event"]
  echo payload
  if payload["comment"]["user"]["type"].getStr == "Bot" or
    payload["comment"]["user"]["login"].getStr == "raboneko" or
    payload["issue"]["user"]["type"].getStr == "Bot" or
    payload["issue"]["user"]["login"].getStr == "raboneko":
    request.respond(204, headers, "")
    return
  let c = newHttpClient()
  c.headers = newHttpHeaders({ "Content-Type": "application/json" })
  if request.headers["X-Github-Event"] == "issue_comment":
    var body = payload["comment"]["body"].getStr.strip.splitLines.map(s => "> " & s).join("\n")
    if body.len > 1000:
      body = body[0 .. 1000] & "…*[comment body truncated]*"
    let json = %*
      { "content": "$1\n-# $2 | [#$3]($4): $5" % [body, payload["comment"]["user"]["login"].getStr, $payload["issue"]["number"].getInt, payload["comment"]["url"].getStr, payload["issue"]["title"].getStr] }
    echo (c.post(DISCORD_WEBHOOK_URL, $json)).status
    request.respond(204, headers, "")
    return
  echo (c.post(DISCORD_WEBHOOK_URL & "/github", request.body)).status
  request.respond(204, headers, "")
  return


var router: Router
router.post("/github-terra", github_terra)

let server = newServer(router)
echo "serving on port: " & $PORT
server.serve(nativesockets.Port(PORT))
