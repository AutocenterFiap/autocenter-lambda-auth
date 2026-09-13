terraform {
  cloud {
    organization = "autocenter-fiap"

    workspaces {
      name = "gateway"
    }
  }
}
