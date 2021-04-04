provider "google" {
  credentials = file("terraform-admin.json")
  project     = "vitalilukashevich1-project"
  region      = "us-central1"
  zone        = "us-central1-a"
}

resource "google_compute_instance" "vm-1-server" {
  name         = "vm-1-server"
  machine_type = "custom-1-2048"
  tags         = ["http-server"]
  boot_disk {
    initialize_params {
      image = "centos-7"
      size  = "20"
      type  = "pd-ssd"
    }
  }
  metadata = {
    ssh-keys = "vitali_lukashevich1:${file("id_rsa.pub")}"
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  connection {
      type        = "ssh"
      user        = "vitali_lukashevich1"
      host        = google_compute_instance.vm-1-server.network_interface.0.access_config.0.nat_ip
      private_key = file("id_rsa")
    }
  provisioner "file" {
    source      = "server.sh"
    destination = "/tmp/server.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/server.sh",
      "sudo sh /tmp/server.sh"
    ]
  }
}

resource "google_compute_instance" "vm-2-client" {
  name         = "vm-2-client"
  machine_type = "custom-1-2048"
  boot_disk {
    initialize_params {
      image = "centos-7"
      size  = "20"
      type  = "pd-ssd"
    }
  }
  metadata = {
    ssh-keys = "vitali_lukashevich1:${file("id_rsa.pub")}"
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  connection {
      type        = "ssh"
      port        = "22"
      user        = "vitali_lukashevich1"
      host        = google_compute_instance.vm-2-client.network_interface.0.access_config.0.nat_ip
      private_key = file("id_rsa")
    }
  provisioner "file" {
    source      = "agent.sh"
    destination = "/tmp/agent.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/agent.sh",
      "sudo sh /tmp/agent.sh ${google_compute_instance.vm-1-server.network_interface.0.network_ip}",
    ]
  }
}
