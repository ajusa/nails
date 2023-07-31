import mummy, webby, std/[cookies, strtabs, sequtils, strutils]
export strtabs, webby

type Response* = object
  headers: HttpHeaders
  code: int

proc query*(req: Request): QueryParams =
  req.uri.parseUrl.query

proc cookies*(req: Request): StringTableRef =
  req.headers["Cookie"].parseCookies

proc redirect*(req: Request, path: string) =
  var headers: HttpHeaders
  headers["Location"] = path
  req.respond(302, headers)

proc respond*(req: Request, body: string) =
  req.respond(200, @[("Content-Type", "text/html")], body)

func params*(req: Request): QueryParams =
  concat(req.query, req.body.parseSearch).QueryParams

proc parseParam*(params: QueryParams; k: string; v: var SomeInteger)
proc parseParam*(params: QueryParams; k: string; v: var SomeFloat)
proc parseParam*(params: QueryParams; k: string; v: var bool)
proc parseParam*(params: QueryParams; k: string; v: var string)
proc parseParam*[T](params: QueryParams; k: string; v: var seq[T])
proc parseParam*[T: object|tuple](params: QueryParams, k: string, v: var T)

proc fillArgs*[T](
  handler: proc(req: Request, args: T) {.gcsafe.}): RequestHandler =
  mixin fromRequest
  proc(req: Request) =
    var args: T
    req.fromRequest(args)
    req.handler(args)

proc fillArgs*[T](
  handler: proc(req: Request, args: var T) {.gcsafe.}): RequestHandler =
  mixin fromRequest
  proc(req: Request) =
    var args: T
    req.fromRequest(args)
    req.handler(args)

proc parseParam*(params: QueryParams; k: string; v: var SomeInteger) =
  v = params[k].parseInt

proc parseParam*(params: QueryParams; k: string; v: var SomeFloat) =
  v = params[k].parseFloat

proc parseParam*(params: QueryParams; k: string; v: var bool) =
  v = k in params

proc parseParam*(params: QueryParams; k: string; v: var string) =
  v = params[k]

proc parseParam*[T](params: QueryParams; k: string; v: var seq[T]) =
  for i, pair in params:
    if pair[0] == k:
      var el: T
      parseParam(params.toBase[i..^1].QueryParams, k, el)
      v.add(el)

proc parseParam*[T: object|tuple](params: QueryParams, k: string, v: var T) =
  for key, value in v.fieldPairs:
    params.parseParam(key, value)

proc fromRequest*[T: object|tuple](req: Request, v: var T) =
  mixin fromRequest
  for key, value in v.fieldPairs:
    when compiles(req.fromRequest(value)):
      req.fromRequest(value)
    else:
      let params = req.params
      params.parseParam(key, value)

proc fromRequest*[T: ref object](req: Request; v: var T) =
  mixin fromRequest
  let params = req.params
  when compiles(new(v)):
    new(v)
  for key, value in v[].fieldPairs:
    when compiles(req.fromRequest(value)):
      req.fromRequest(value)
    else:
      params.parseParam(key, value)
