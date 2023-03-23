#include "networkrequestmanager.h"
#include <QStandardPaths>
#include <QDir>

NetworkRequestManager::NetworkRequestManager(QObject *parent) : QObject(parent)
{
	m_networkAccessManager = new QNetworkAccessManager(this);
	m_networkAccessManager->setNetworkAccessible(QNetworkAccessManager::Accessible);
	m_diskCache = new QNetworkDiskCache(this);
	m_diskCache->setCacheDirectory(QStandardPaths::writableLocation(QStandardPaths::CacheLocation)+QDir::separator()+"oslistcache");
	m_networkAccessManager->setCache(m_diskCache);
}

void NetworkRequestManager::onError(QNetworkReply::NetworkError code)
{
    qDebug() << "onErrorRequest: " << code;
}

QNetworkRequest NetworkRequestManager::buildRequest(const QString url, QMap<QString, QString> headerData)
{
	QNetworkRequest request;
	request.setUrl(QUrl(url));
//	setUserAgent(QString("Mozilla/5.0 rpi-imager/%1").arg(constantVersion()).toUtf8());
	return request;
}

void NetworkRequestManager::processReply(QNetworkReply *reply, const QString type)
{
	reply->deleteLater();
	// no error in request
	if (reply->error() == QNetworkReply::NoError)
	{
	    // get HTTP status code
	    qint32 httpStatusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

	    // 200
	    if (httpStatusCode >= 200 && httpStatusCode < 300) {
		QByteArray replyBytes = reply->readAll();
		emit replyFinished(reply->request().url().toString(), type, QString(replyBytes));
		qDebug() << "[DONE] Emitted reply finished for " << type;
	    } else if (httpStatusCode >= 300 && httpStatusCode < 400) { // 300 Redirect
		QUrl relativeUrl = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
		QUrl redirectUrl = reply->url().resolved(relativeUrl);
		m_diskCache->clear();
//		reply->manager()->get(QNetworkRequest(redirectUrl));
		return;
	    } else
	    {
		qDebug() << "Error: Status code invalid! " << httpStatusCode;
	    }
	} else {
	    qDebug() << "Error: " << reply->errorString();
	}

	reply->close();
//	reply->manager()->deleteLater();
}

void NetworkRequestManager::getRequest(const QString url, QString type)
{
	QNetworkRequest req = buildRequest(url, {});
	qDebug() << "[GET REQ] " << url << " " << type;

	QNetworkReply *reply = m_networkAccessManager->get(req);
	connect(reply, &QNetworkReply::finished,
		[this, type, reply]() {
		qDebug() << "[PROCESS] processing request " << type;
		processReply(reply, type);
	});
}
