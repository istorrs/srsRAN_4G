#!/bin/bash
set +x  # Enable debugging
WORKING_CONF_FOLDER=/home/stevew/.config/srsran
WORKING_CONF_FILE=enb_1tx2rx_no_mimo_50_prb.conf
DEFAULT_CONF_FOLDER=/root/.config/srsran
echo "Cleaning up old logs"
sudo rm /tmp/enb*.log
sudo mkdir -p /root/.config/srsran
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
echo "--------------------------------------------------------------------------------------"
echo "Starting /usr/local/bin/srsenb with config ${WORKING_CONF_FOLDER}/${WORKING_CONF_FILE}"
cat  ${WORKING_CONF_FOLDER}/${WORKING_CONF_FILE} | grep device_args
echo "--------------------------------------------------------------------------------------"
sudo /usr/local/bin/srsenb \
	--enb_files.sib_config=${WORKING_CONF_FOLDER}/sib.conf \
        --enb_files.rr_config=${WORKING_CONF_FOLDER}/rr.conf \
  	--enb_files.rb_config=${WORKING_CONF_FOLDER}/rb.conf \
  	--log.filename=/tmp/enb.log \
  	--pcap.filename=/tmp/enb_mac.pcap \
 	--pcap.nr_filename=/tmp/enb_mac_nr.pcap \
  	--pcap.s1ap_filename=/tmp/enb_s1ap.pcap \
  	--pcap.ngap_filename=/tmp/enb_ngap.pcap \
  	--expert.metrics_csv_enable=0 \
  	--expert.metrics_csv_filename=/tmp/enb_metrics.csv \
  	--expert.report_json_enable=0 \
  	--expert.report_json_filename=/tmp/enb_report.json \
  	--expert.alarms_filename=tmp/enb_alarms.log \
  	--expert.tracing_filename=tmp/enb_tracing.log \
	${WORKING_CONF_FOLDER}/${WORKING_CONF_FILE}
