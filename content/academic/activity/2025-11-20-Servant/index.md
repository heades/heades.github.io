+++
type = 'academic'
layout = 'post'
title = "All about Servant"
date = '2025-12-08'

[activity]
type = 'post'
authors = ['Harley Eades III']
tags = ['haskell','web api', 'servant', 'web development']
+++

**I'm live writing this, and so this document is ALIVE (ALIVE, IT'S ALIVE), so
expect there to be errors, gaps, and no ending (yet).**

Servant is a Haskell library for writing web API's. Some research I'm starting
up requires that I understand how it works. So I thought I'd write up my notes
here. These notes simply follow along with the 
[Servant Documentation](https://docs.servant.dev/en/latest/index.html).

# Setup

I'm using Docker Compose with two services: a service called `servant` and a
service called `database`. The latter is the default Postgres image from
DockerHub, but I wrote a custom `init.db` script that populates it with a schema
and dataset of random information from the Mega Man video game. I'll use this
data to write queries that will modify and read an actual database.

The [Servant Documentation](https://docs.servant.dev/en/latest/index.html) does
mention that there is a Stack template, but I wanted to start from scratch to
better understand everything. I simply created a new stack project with `stack
--init` with the bare template.

# A Simple API
We will start with a simple query that does no filtering. Looks like they
recommend that we put our API into it's own Haskell module. I created a new
module called `WebAPIType` which will contain the web API. Servant's whole bag
is the specification of the API at the type level. So this module will contain
that type or several types. Since we are working at the type level it makes
sense that we need language extensions:

```.haskell
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
```

I'll start by creating a single query for pulling all the Mega Man games which
has the following schema:

```.sql
CREATE TABLE IF NOT EXISTS games (
  game_id           BIGSERIAL PRIMARY KEY,
  slug              TEXT NOT NULL UNIQUE CHECK (is_valid_slug(slug)),
  title             TEXT NOT NULL,
  series_number     SMALLINT CHECK (series_number > 0),
  release_date      DATE,
  platform          TEXT,               -- e.g., "NES", "SNES", "PS4"
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

We can define the `Game` record as follows:

```.haskell
type Date = UTCTime

data Game = Game {
    title :: Text,
    seriesNumber :: Integer,
    releaseDate :: Date,
    platform :: Text
}
```
This can easily be encoded and decoded from JSON which Servant takes care of for
us. Since we are using `Text` and `UTCTime` we also need the following imports:

```.haskell
import Servant.API
import Data.Time (UTCTime)
import Data.Text (Text)
```

Now using the `Game` record we define the `GameAPI` type as follows:

```.haskell
type GameAPI = "games" :> Get '[JSON] [Game]
```
Let's break this type's definition down:

- `"games"` is the name of our query.
- `:>` is a Servant operator that we use to create path in our API queries. We
  can think of `:>` as simply `/` where the last element in the chain of `:>`'s
  is the operation at that path. So `"games" :> Get '[JSON] [Game]` is
  equivalent to the path `/games` and it performs a `Get`, but if I did `"seg1"
  :> "seg2" :> "seg3" :> Get '[JSON] [b]` then we obtain a path `/seg1/seg2/se3`
  which will perform a `Get`. 
- `Get a b` describes the type of request being made at the path we describe
  using `:>`. This is a GET request and it'll return a `b` encoded as an `a`. So
  if `a` is `'[JSON]`, then `b` is encoded as a JSON response using 
  [Aeson](https://hackage.haskell.org/package/aeson).

  Next we need to actually serve the API. We'll create a new module called
  `Server` for this. First, we import the `WebAPI`:

  ```.haskell
  import WebAPIType (GameAPI, Game)
  ```

Then from Servant we will need the following:

```.haskell
import Servant (Server, Application, Proxy(..), serve)
```

`Server` is the type of the server that we will create from our API `GameAPI`.
It is here that we connect the API to our server-side resolver (Servant calls
these handlers). It has the following definition:

```.haskell
class HasServer api context where
  type ServerT api (m :: Type -> Type) :: Type

  route ::
       Proxy api
    -> Context context
    -> Delayed env (Server api)
    -> Router env

  hoistServerWithContext
      :: Proxy api
      -> Proxy context
      -> (forall x. m x -> n x)
      -> ServerT api m
      -> ServerT api n

type Server api = ServerT api Handler
```

This is a cool way to define the `Server` type, using a type class, because now
Servant can create different instances based on how the API is defined. For
example, if one of your endpoints in your API route requires input, then Servant
will require your resolver to be a function where the input is this input to the
route. We will see some examples of this later.

The `Proxy` type is used to create a witness to all our type-level magic. We
give the proxied API to the `serve` command when we create our final Servant
`Application`. This application can then be given to the Wai Warp server which
allows us to actually serve our API on a port of our system.

The `GameAPI` can now be turned into something servable using the above:

```.haskell
games :: [Game]
games = []

serverGames :: Server GameAPI
serverGames = return games

-- Actually build the api:
gamesAPI :: Proxy GameAPI
gamesAPI = Proxy

gamesApp :: Application
gamesApp = serve gamesAPI serverGames
```

One question I currently have is, can `games` exist in the IO monad? I'll need
to query the database which will need to be in IO.

Finally, we can serve our API using the following:

```.haskell
module Main (main) where

import Server (gamesApp)

import Network.Wai.Handler.Warp (run)

main :: IO ()
main = run 5000 gamesApp
```

Let's try and get this connected to the database using the [HASQL Library](https://hackage.haskell.org/package/hasql).

## The Database

[HASQL Library](https://hackage.haskell.org/package/hasql) appears to be the
best option for connecting to Postgres that is production grade. In this section
we will setup HASQL within our example Servant application. This will allow us
to conduct more realistic experiments to help our understanding.

Getting HASQL installed was a little bit of a challenge, because I didn't want
to install the full Postgres database in the container of our example API,
because it runs in a separate container as its own service. So I just want to
connect to it using HASQL as a client. This requires the following packages be
installed in the API's container:

```
- libpq-dev
- postgresql-client
```

These got HASQL to fully install as part of our project. I also needed to add
the following dependencies to my `stack.yaml`'s `extra-deps`:

```
- testcontainers
- testcontainers-postgresql
- text-builder-core
- text-builder
```

HASQL wouldn't compile without them. Now that I have a working build we can
proceed with setting up HASQL to query my database. I created a new module
`Database` to house all of our database specific code. 

First, we have to establish a connection with the database. Based on the
documentation we should use these:

```.haskell
Hasql.Connection
Hasql.Connection.Setting
Hasql.Connection.Setting.Connection
```

I setup a database settings record:

```.haskell
data ConnectionSettings = ConnectionSettings {
    ipAddr :: String,
    port :: Int,
    user :: String,
    dbname :: String
}

settings :: ConnectionSettings
settings = ConnectionSettings {
    ipAddr = "123.4.5.6",
    port = 5432,
    user = "postgres",
    dbname = "postgres"
}
```

Then we can establish a connection to the database using `Connection.acquire ::
[Setting] -> IO (Either ConnectionError Connection)` where we first define a
`Setting` as a Postgres connection string:

```.haskell
psqlSettings :: T.Text
psqlSettings = T.pack $ "host="++settings.ipAddr++" dbname="++settings.dbname++" user="++settings.user++" port="++(show settings.port)

connect :: IO (Either Connection.ConnectionError Connection.Connection)
connect = Connection.acquire [connectSettings]
    where
        connectSettings = ConnectionSetting.connection $ ConnectionSettingConnection.string psqlSettings
```

Updating the main loop to make a connection to the database is pretty easy now:

```.haskell
main :: IO ()
main = do
    _dbconn <- connect
    case _dbconn of
        Left err -> putStrLn . show $ err
        Right dbconn -> do putStrLn "Connected to Postgres"
                          hFlush stdout
                          -- Make use of dbconn.
                          run 5000 gamesApp
```

In order to pass the database connection to `gamesApp`, we modify the type of
`gamesApp` placing it into the `Control.Monad.Reader` monad.

```.haskell
gamesApp :: Reader Connection Application
gamesApp = do
    sg <- serverGames
    return $ serve gamesAPI sg
```

Since the resolution of the query happens in `serverGames` we update it as well:

```.haskell
serverGames :: Reader Connection (Server GameAPI)
serverGames = do
    dbconn <- ask
    return . liftIO $ games dbconn
```

The type of `gamesProxy` doesn't need to change, because it does'nt need to
access the database. However, `games` is the resolution function, and hence does
need access to the database, but we update it as a pure function:

```.haskell
games :: Connection -> IO [Game]
games dbconn = return []
```

We now have access to the database in the resolution function for the `games`
query. So the next step is to actually write an SQL query for all of the games
in the database, and execute the query on the database using `dbconn`. 

Querying the database requires us to define two things: a `Statement` and a
`Session`. The former boils down to the actual Postgres query while the latter
is the action, synthesized from the statement, to be executed on the database
connection.  Then we simply pass the database connection and the session to the
`run` function and the query will be executed on the database.

These both require encoding/decoding of the data to/from the database and
Haskell. I defined the encoding between `Game` and Postgres as follows:

```.haskell
gameParams :: HEnc.Params Game
gameParams = (title >$< HEnc.param (HEnc.nonNullable HEnc.text))
          <> (fmap fromInteger . seriesNumber >$< HEnc.param (HEnc.nullable HEnc.int8))
          <> (releaseDate >$< HEnc.param (HEnc.nullable HEnc.timestamptz))
          <> (platform >$< HEnc.param (HEnc.nullable HEnc.text))
```

This encoder allows for the `Game` record to be given as a parameter to an SQL
statement. Each field of `Game` needs it's own encoding using 
`param :: NullableOrNot Value a -> Params a` that takes as input an encoder
between a Postgres value that can be nullable or not and a Haskell type. We
compose this encoder with the projection function of the field we are encoding.
For example,

```.haskell
fmap fromInteger . seriesNumber >$< HEnc.param (HEnc.nullable HEnc.int8)
```

This encoder of the `seriesNumber` field, first projects the series number, then
converts it into an `Int64` which is then encoded as a parameter into Postgres.
We need the call to `fmap`, because the series number is nullable, hence the
type of `seriesNumber` is `Maybe Integer` and we need a `Maybe Int64` which is
encodable into Postgres.

Decoding is opposite, but operates at the row level of the returned data from
the database. Ultimately, we wish to query for the list of all `Game`'s which
corresponds to a list of games `[Game]`. Decoding a list of games is easy if we
can decode  single row containing a `Game`. We do this as follows:

```.haskell
gameRow :: HDec.Row Game
gameRow = Game <$> HDec.column (HDec.nonNullable HDec.text)               -- title
               <*> HDec.column (HDec.nullable (fmap toInteger HDec.int8)) -- seriesNumber
               <*> HDec.column (HDec.nullable HDec.timestamptz)           -- releaseDate
               <*> HDec.column (HDec.nullable HDec.text)                  -- platform
```

Here `gameRow` returns `Game` record by decoding each column of the row. The
title of the game is decoded as:

```.haskell
HDec.column (HDec.nonNullable HDec.text) -- title
```

This says, decode this column as a `Text` value that is non-nullable. Thus, the
above code has the type `Row Text` whereas the following:

```.haskell
HDec.column (HDec.nullable (fmap toInteger HDec.int8)) -- seriesNumber
```

has type `Row (Maybe Integer)`, because the series number is nullable.

Next we use this decoder to decode lists of `Games`:

```.haskell
gamesDecoder :: HDec.Result [Game]
gamesDecoder = HDec.rowList gameRow
```

We use the library function `rowList :: Row a -> Result [a]` to lift our `Game`
decoder to lists. At this point we have everything we need to be able to resolve
queries using the database.

## Query Resolution

In the previous section we finished with needing to define a `Statement` and a
`Session` in order to execute a query on the database. These are both coupled
tightly to the actual query being resolved by Servant; and thus, we define these
as part of the resolver for our `games` query in the module `Resolver`. The
actual SQL statement we wish to execute is defined as a Hasql `Statement`:

```.haskell
selectGames :: Statement () [Game]
selectGames = Statement sql HEnc.noParams gamesDecoder True
    where
        sql = "select title, series_number, release_date, platform from games"
```

The `selectGames` statement simply configures Hasql for parsing the SQL
statement `sql`. This statement has no parameters indicated by using `noParams`,
Hasql should decode the returned data using the `gamesDecoder` defined in the
previous section, and finally, Hasql should execute this as a single query
indicated by `True` which should improve performance (based on the Hasql
documentation).

Using `selectGames` we can define our Hasql `Session`:

```.haskell
gamesSession :: Session [Game]
gamesSession = statement () selectGames
```

Since we have no parameters we give
`statement :: params -> Statement params result -> Session result` 
the unit `()`, but give `selectGames` as our result.

Now we can use `gamesSession` to define our resolver for our `games` Servant
query:

```.haskell
games :: Connection -> IO [Game]
games dbconn = do
    result <- run gamesSession dbconn
    case result of
        Left err -> error . show $ err
        Right g -> do print g
                      hFlush stdout
                      return g
```

We first run the `gamesSession` on the database using the given connection
`dbconn`, and then simply case split on the result to determine if we got an
error or a value result.

## Executing a query

We can now execute our `games` query to obtain the list of games:

```.bash
# curl http://localhost:5000/games
[{"platform":"NES","releaseDate":"2000-01-01T01:11:34.962898Z","seriesNumber":1,"title":"Mega Man"},
  {"platform":"NES","releaseDate":"2000-01-01T01:11:34.963271Z","seriesNumber":2,"title":"Mega Man 2"},
  {"platform":"NES","releaseDate":"2000-01-01T01:11:34.963914Z","seriesNumber":3,"title":"Mega Man 3"},
  {"platform":"SNES","releaseDate":"2000-01-01T01:11:34.96509Z","seriesNumber":1,"title":"Mega Man X"},
  {"platform":"PS4","releaseDate":"2000-01-01T00:00:00.006849Z","seriesNumber":11,"title":"Mega Man 11"}]
```

As we can see all of the games in our database are returned. 

# Extending our simple API

Now let's try adding a new endpoint I'll call "character" that will return a
list of characters based on a JSON request with some detail we will use to
filter the response. 

A character is defined as follows:

```.haskell
data Character = Character {
    displayName :: Text,
    kind :: Text,
    alignment :: Text,
    debut_game :: Maybe Text,
    description :: Maybe Text
} deriving (Eq, Show, Generic)

instance ToJSON Character
instance FromJSON Character
```

Then we will pass in via JSON a character detail:

```.haskell
data CharDetails = DisplayName Text 
                 | Kind Text
                 | Alignment Text
  deriving (Eq, Show, Generic)

instance FromJSON CharDetails

newtype GetCharDetails = GetCharDetails {
    details :: CharDetails
} deriving (Eq, Show, Generic)

instance FromJSON GetCharDetails
```

The type `GetCharDetails` will be the structure of our JSON. For example,

```.json
{
  "details": {
    "tag": "DisplayName", 
    "contents": "Mega Man"
  }
}
```

Now we can add a new endpoint to our `GameAPI`:

```.haskell
type GameAPI = "games"     :> Get '[JSON] [Game]
          :<|> "character" :> ReqBody '[JSON] GetCharDetails :> Post '[JSON] [Character]
```

Servant allows us to name the endpoint "character" and then require a JSON
request body whose contents must parse as a `GetCharDetails` (the parsing will
be done using AESON). Since we are passing information to the server we must do
this through a POST request. Servant makes this pretty easy! 

After updating the definition of our API type, we will need to update our
server. Based on how we wrote the `gamesApp` which serves the API we do not need
to change it. 

However, our server `serverGames` now requires we define our resolvers as
Servant handlers:

```.haskell
characterHandler :: Connection -> GetCharDetails -> Handler [Character]
characterHandler dbconn deets = liftIO $ character dbconn (details deets)

gamesHandler :: Connection -> Handler [Game]
gamesHandler dbconn = liftIO $ games dbconn
```

The handler `gamesHandler` doesn't change, except for being in the `Handler`
monad. The handler for our new endpoint `characterHandler` takes as input a
database connection as well as a `GetCharDetails` which is the character details
obtained from the JSON request body. In Servant, this simply corresponds to a
new argument to the function. We implement this handler as follows:

```.haskell
characterHandler :: Connection -> GetCharDetails -> Handler [Character]
characterHandler dbconn deets = liftIO $ character dbconn (details deets)
```

We simply call a resolver function that operates in `IO` and lift its result
into the `Handler` monad. This allows `character` to be written fairly simply.

```.haskell
character :: Connection -> CharDetails -> IO [Character]
character dbconn details = do
    print details
    hFlush stdout
    result <- run (characterSession details) dbconn
    case result of
        Left err -> error . (++"\n") . show $ err
        Right g -> do print g
                      hFlush stdout
                      return g
```
In fact, the only differences from the `games` resolver is that we call
`characterSession` the Hasql session for executing the SQL query on our database
using the character details, `details`.

Then `characterSession` case splits on which character detail was passed in, and
filter our results based on that:

```.haskell
characterSession :: CharDetails -> Session [Character]
characterSession (DisplayName name) = statement name $ Statement sql textEncoder characterDecoder True
    where 
        sql = sqlStr $ selectCharacterBySQL "characters.display_name"
characterSession (Kind kind) = statement kind $ Statement sql textEncoder characterDecoder True
    where 
        sql = sqlStr $ selectCharacterBySQL "characters.kind"
characterSession (Alignment alignment) = statement alignment $ Statement sql textEncoder characterDecoder True
    where 
        sql = sqlStr $ selectCharacterBySQL "characters.alignment"

selectCharacterBySQL :: String -> String
selectCharacterBySQL field = "SELECT display_name,kind,alignment,games.title AS game_title,description FROM characters INNER JOIN games on characters.debut_game_id = games.game_id WHERE "++field++" = $1"
```

One thing to note about this, I tried to use the Hasql template haskell library
(Hasql-TH) to write my SQL statement, but since I'm using records, and in the
future, nested records, it doesn't support it. However, even for simple types I
found it a lot easier to actually just write my own encoder/decoders for my
data. The fact that there really isn't any documentation for Hasql-TH made it
even more difficult. 

Besides the encoders for the data, this is all it took to extend our API with a
more advanced endpoint. Here is an example query:

```
# curl -X POST -H "Content-Type: application/json" -d '{"details": {"tag": "Alignment", "contents": "villain"}}' http://localhost:5000/character
[{"alignment":"villain","debut_game":"Mega Man","description":"Mad scientist","displayName":"Dr. Wily","kind":"scientist"},
 {"alignment":"villain","debut_game":"Mega Man","description":"Timber-cutting robot","displayName":"Cut Man","kind":"robot_master"},
 {"alignment":"villain","debut_game":"Mega Man","description":"Super-strong construction robot","displayName":"Guts Man","kind":"robot_master"},
 {"alignment":"villain","debut_game":"Mega Man","description":"Cold-weather robot","displayName":"Ice Man","kind":"robot_master"},
 {"alignment":"villain","debut_game":"Mega Man","description":"Demolition robot","displayName":"Bomb Man","kind":"robot_master"},
 {"alignment":"villain","debut_game":"Mega Man","description":"Waste disposal robot","displayName":"Fire Man","kind":"robot_master"},
 {"alignment":"villain","debut_game":"Mega Man","description":"Power plant robot","displayName":"Elec Man","kind":"robot_master"},
 {"alignment":"villain","debut_game":"Mega Man 2","description":"Uses deadly Metal Blades","displayName":"Metal Man","kind":"robot_master"},
 {"alignment":"villain","debut_game":"Mega Man 2","description":"Controls wind attacks","displayName":"Air Man","kind":"robot_master"}]
```

To be continued....

# Authorization (TBA)

Authorization uses [Basic Auth](https://en.wikipedia.org/wiki/Basic_access_authentication)