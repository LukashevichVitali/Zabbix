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

  provisioner "file" {
    source      = "server.sh"
    destination = "/tmp/server.sh"
    connection {
      type        = "ssh"
      port        = "22"
      user        = "vitali_lukashevich1"
      host        = google_compute_instance.vm-1-server.network_interface.0.access_config.0.nat_ip
      private_key = file("id_rsa")
    }
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      port        = "22"
      user        = "vitali_lukashevich1"
      host        = google_compute_instance.vm-1-server.network_interface.0.access_config.0.nat_ip
      private_key = file("id_rsa")
    }
    inline = [
      "chmod +x /tmp/server.sh",
      "cd /tmp/",
      "sudo ./server.sh"
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
  provisioner "file" {
    source      = "agent.sh"
    destination = "/tmp/agent.sh"
    connection {
      type        = "ssh"
      port        = "22"
      user        = "vitali_lukashevich1"
      host        = google_compute_instance.vm-2-client.network_interface.0.access_config.0.nat_ip
      private_key = file("id_rsa")
    }
  }
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "vitali_lukashevich1"
      host        = google_compute_instance.vm-2-client.network_interface.0.access_config.0.nat_ip
      private_key = file("id_rsa")
    }
    inline = [
      "chmod +x /tmp/agent.sh",
      "cd /tmp/",
      "sudo ./agent.sh ${google_compute_instance.vm-1-server.network_interface.0.network_ip}",
    ]
  }
}
