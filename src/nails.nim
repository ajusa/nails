import mummy, webby, std/[cookies, strtabs]
export strtabs, webby

type Response* = object
  headers: HttpHeaders
  code: int

proc query*(req: Request): QueryParams =
  req.uri.parseUrl.query

proc cookies*(req: Request): StringTableRef =
  req.headers["Cookie"].parseCookies

proc getOrDefault*(params: QueryParams, key, default: string): string =
  if key in params: params[key] else: default

proc redirect*(req: Request, path: string) =
  var headers: HttpHeaders
  headers["Location"] = path
  req.respond(302, headers)

template wire*(module: untyped, meth: untyped): untyped =
  block:
    proc handler(req: Request) =
      var headers: HttpHeaders
      headers["Content-Type"] = "text/html"
      var response = Response(headers: headers, code: 200)
      when compiles(module.meth(req)):
        when not (type(module.meth(req)) is void):
          let tmp = module.meth(req)
        else:
          module.meth(req)
      when compiles(tmp.meth):
        let resp = tmp.meth
        if not req.responded:
          req.respond(response.code, response.headers, resp)
      when compiles(meth()):
        let resp = meth
        if not req.responded:
          req.respond(response.code, response.headers, resp)
    handler