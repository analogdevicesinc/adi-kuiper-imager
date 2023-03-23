#ifndef NETWORKREQUESTMANAGER_H
#define NETWORKREQUESTMANAGER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QString>
#include <QMap>
#include <QNetworkReply>
#include <QNetworkDiskCache>

class NetworkRequestManager : public QObject
{
	Q_OBJECT
public:
	NetworkRequestManager(QObject *parent);
	virtual ~NetworkRequestManager() {}

	Q_INVOKABLE void getRequest(const QString url, QString type);

Q_SIGNALS:
	void replyFinished(QVariant url, QVariant type, QVariant reply);

public Q_SLOTS:
	void onError(QNetworkReply::NetworkError code);
	void processReply(QNetworkReply *reply, const QString type);
private:
	QNetworkRequest buildRequest(const QString url, QMap<QString, QString> headerData);
	QNetworkAccessManager *m_networkAccessManager;
	QNetworkDiskCache *m_diskCache;
	QString m_current_type;
};




#endif // NETWORKREQUESTMANAGER_H
