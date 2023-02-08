#ifndef NETWORKACCESSMANAGERFACTORY_H
#define NETWORKACCESSMANAGERFACTORY_H

/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright (C) 2020 Raspberry Pi (Trading) Limited
 */

#include <QQmlNetworkAccessManagerFactory>

class QNetworkDiskCache;

class NetworkAccessManagerFactory : public QObject, public QQmlNetworkAccessManagerFactory
{
    Q_OBJECT
public:
    NetworkAccessManagerFactory();
    virtual QNetworkAccessManager *create(QObject *parent);

public Q_SLOTS:
    void forceCleanupCache();

protected:
    QNetworkDiskCache *_c;
};

#endif // NETWORKACCESSMANAGERFACTORY_H
