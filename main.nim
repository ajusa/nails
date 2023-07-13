import mummy, mummy/routers, nails, post_controller

var router: Router
router.get("/", wire(post_controller, index))

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
