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
    source      = "skript_test.sh"
    destination = "/tmp/skript_test.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/skript_test.sh",
      "sudo sh /tmp/skript_test.sh"
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
    user        = "vitali_lukashevich1"
    host        = google_compute_instance.vm-2-client.network_interface.0.access_config.0.nat_ip
    private_key = file("id_rsa")
  }
  provisioner "file" {
    source      = "tomcat.sh"
    destination = "/tmp/tomcat.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/tomcat.sh",
      "sudo sh /tmp/tomcat.sh"
    ]
  }
}
