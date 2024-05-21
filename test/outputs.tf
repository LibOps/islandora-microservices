output "urls" {
  value = {
    crayfits  = module.crayfits.urls[random_shuffle.region.result[0]],
    homarus   = module.homarus.urls[random_shuffle.region.result[0]],
    houdini   = module.houdini.urls[random_shuffle.region.result[0]],
    hypercube = module.hypercube.urls[random_shuffle.region.result[0]]
  }
}
