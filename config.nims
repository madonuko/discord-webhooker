import std/os
import dotenv

dotenv.load()

let webhook_url = getEnv("DISCORD_WEBHOOK_URL")
if webhook_url == "":
  echo "$DISCORD_WEBHOOK_URL is not set, make sure it exists in your .env file or as an environment variable."
  quit 1

switch("d", "DISCORD_WEBHOOK_URL=" & webhook_url)
