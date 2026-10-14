resource "yandex_compute_snapshot_schedule" "snap" {
  name        = "snap"
  description = "Автоматической ежедневное копирование"

  schedule_policy {
    expression = "0 0 * * *"
  }

  retention_period = "168h" #неделя

  #выбираются первые диски виртуальных машин
  disk_ids = [
    yandex_compute_instance.web_a.boot_disk[0].disk_id,
    yandex_compute_instance.web_b.boot_disk[0].disk_id,
    yandex_compute_instance.elastic.boot_disk[0].disk_id,
    yandex_compute_instance.kibana.boot_disk[0].disk_id,
    yandex_compute_instance.zabbix.boot_disk[0].disk_id,
  ]
}