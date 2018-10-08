#!/bin/sh

# Chinachu が持っている ffmpeg を使うことができます。
# サポートされている動画形式を調べるには:
# ./chinachu test ffmpeg -formats
# ./chinachu test ffmpeg -encoders
#残課題：trap対処

#変数設定
FFMPEG_COM="nice -n 19 /home/chinachu/chinachu/usr/bin/ffmpeg -i "
FFMPEG_OP=" -deinterlace -c:v hevc -preset medium -crf 28 -c:a aac -b:a 128k "
#REC_DIR="/home/chinachu/chinachu/recorded"
#pt3録画機のディレクトリをnfsから参照しエンコード
REC_DIR="/mnt/chinachu1/chinachu/recorded/"
ENC_LIST="/home/chinachu/script/encode/enc.list"
MP4_DIR="/home/chinachu/mp4"
M2TS_DIR="/home/chinachu/m2ts"
DATE_TIME=`date +%Y%m%d`
LOG_FILE="/home/chinachu/script/encode/log/${DATE_TIME}_encode.sh.log"
ERR_LOG_FILE="/home/chinachu/script/encode/log/enchode.sh.err.log"
LOCK_FILE="/home/chinachu/script/encode/lock.txt"

#二重起動チェック
if [ -f ${LOCK_FILE} ] ; then
	NOW_TIME=`date "+%Y/%m/%d %H:%M:%S"`
	echo "${NOW_TIME} エンコードシェルは既に起動しています。" >> ${LOG_FILE} 2>&1
	echo "${NOW_TIME} エンコードシェルは既に起動しています。" >> ${ERR_LOG_FILE} 2>&1
	exit 1
fi

#ロックファイル作成
touch ${LOCK_FILE}

#開始MSG出力
NOW_TIME=`date "+%Y/%m/%d %H:%M:%S"`
echo "${NOW_TIME} エンコードを開始します。" >> ${LOG_FILE}

#recフォルダ内ファイルの一覧出力
ls -1 ${REC_DIR} > ${ENC_LIST}

#一覧のファイル分ループ
for LINE in `cat ${ENC_LIST}`
do

	#動画ファイルエンコード
	echo ${FFMPEG_COM} "${REC_DIR}/${LINE}" ${FFMPEG_OP} "${MP4_DIR}/${LINE}.mp4" >> ${LOG_FILE} 2>&1
	${FFMPEG_COM} "${REC_DIR}/${LINE}" ${FFMPEG_OP} "${MP4_DIR}/${LINE}.mp4" >> ${LOG_FILE} 2>&1

	#エンコード成否確認
	if [ $? -ne 0 ] ; then
		NOW_TIME=`date "+%Y/%m/%d %H:%M:%S"`
		echo "${NOW_TIME} エンコードに失敗しました。ファイル名：${REC_DIR}/${LINE}" >> ${LOG_FILE} 2>&1
		echo "${NOW_TIME} エンコードに失敗しました。ファイル名：${REC_DIR}/${LINE}" >> ${ERR_LOG_FILE} 2>&1
		continue
	fi

	#エンコード元ファイル削除
	mv -f "${REC_DIR}/${LINE}" "${M2TS_DIR}/${LINE}"
	rm -f "${M2TS_DIR}/${LINE}"
	
	#ファイル移動成否確認
	if [ -f "${M2TS_DIR}/${LINE}" ] ; then
		NOW_TIME=`date "+%Y/%m/%d %H:%M:%S"`
		echo "${NOW_TIME} ファイル削除に失敗しました。ファイル名：${REC_DIR}/${LINE}" >> ${LOG_FILE} 2>&1
		echo "${NOW_TIME} ファイル削除に失敗しました。ファイル名：${REC_DIR}/${LINE}" >> ${ERR_LOG_FILE} 2>&1
		continue
	fi
	
done

#終了処理
NOW_TIME=`date "+%Y/%m/%d %H:%M:%S"`
echo "${NOW_TIME} エンコードを終了します。" >> ${LOG_FILE}
rm -f ${LOCK_FILE}

exit