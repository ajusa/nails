import mummy
type Post = object
  text: string
  author: string

type PostView = object
  posts: seq[Post]

proc index*(req: Request): PostView =
  result.posts = @[Post(text: "hello world", author: "me")]

proc index*(postView: PostView): string =
  for post in postView.posts:
    result &= $post
