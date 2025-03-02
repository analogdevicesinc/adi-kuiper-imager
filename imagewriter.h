#ifndef IMAGEWRITER_H
#define IMAGEWRITER_H

/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright (C) 2020 Raspberry Pi (Trading) Limited
 */

#include <QObject>
#include <QTimer>
#include <QUrl>
#include <QSettings>
#include <QVariant>
#include "config.h"
#include "powersaveblocker.h"
#include "drivelistmodel.h"

class QQmlApplicationEngine;
class DownloadThread;
class QNetworkReply;
class QWinTaskbarButton;

class ImageWriter : public QObject
{
    Q_OBJECT
public:
    explicit ImageWriter(QObject *parent = nullptr);
    virtual ~ImageWriter();
    void setEngine(QQmlApplicationEngine *engine);

    /* Set URL to download from, and if known download length and uncompressed length */
    Q_INVOKABLE void setSrc(const QUrl &url, quint64 downloadLen = 0, quint64 extrLen = 0, QByteArray expectedHash = "", bool multifilesinzip = false,  bool skipformat = false, QString parentcategory = "", QString osname = "");

    /* Set device to write to; Return true if set is successfully and false if device is already selected */
    Q_INVOKABLE bool setDst(const QString &device, quint64 deviceSize = 0, QStringList mountpoints = {});

    /* Enable/disable verification */
    Q_INVOKABLE void setVerifyEnabled(bool verify);

    /* Returns true if src and dst are set */
    Q_INVOKABLE bool readyToWrite();

    /* Start writing */
    Q_INVOKABLE void startWrite();

    /* Cancel write */
    Q_INVOKABLE void cancelWrite();

    /* Return true if url is in our local disk cache */
    Q_INVOKABLE bool isCached(const QUrl &url, const QByteArray &sha256);

    /* Start polling the list of available drives */
    Q_INVOKABLE void startDriveListPolling();

    /* Stop polling the list of available drives */
    Q_INVOKABLE void stopDriveListPolling();

    /* Return list of available drives. Call startDriveListPolling() first */
    DriveListModel *getDriveList();

    /* Utility function to return filename part from URL */
    Q_INVOKABLE QString fileNameFromUrl(const QUrl &url);

    /* Function to return OS list URL */
    Q_INVOKABLE QUrl constantOsListUrl() const;

    /* Function to return OS list URL */
    Q_INVOKABLE QUrl constantProjListUrl() const;

    /* Function to return version */
    Q_INVOKABLE QString constantVersion() const;

    /* Returns true if version argument is newer than current program */
    Q_INVOKABLE bool isVersionNewer(const QString &version);

    /* Set custom repository */
    Q_INVOKABLE void setCustomOsListUrl(const QUrl &url);

    /* Utility function to open OS file dialog */
    Q_INVOKABLE void openFileDialog();

    /* Return filename part of URL set */
    Q_INVOKABLE QString srcFileName();

    /* Returns true if online */
    Q_INVOKABLE bool isOnline();

    /* Returns true if run on embedded Linux platform */
    Q_INVOKABLE bool isEmbeddedMode();

    /* Mount any USB sticks that can contain source images under /media
       Returns true if at least one device was mounted */
    Q_INVOKABLE bool mountUsbSourceMedia();

    /* Returns a json formatted list of the OS images found on USB stick */
    Q_INVOKABLE QByteArray getUsbSourceOSlist();

    /* Functions to collect information from computer running imager to make image customization easier */
    Q_INVOKABLE QString getDefaultPubKey();
    Q_INVOKABLE QString getTimezone();
    Q_INVOKABLE QStringList getTimezoneList();
    Q_INVOKABLE QStringList getCountryList();
    Q_INVOKABLE QString getSSID();
    Q_INVOKABLE QString getPSK(const QString &ssid);

    Q_INVOKABLE bool getBoolSetting(const QString &key);
    Q_INVOKABLE void setSetting(const QString &key, const QVariant &value);
    Q_INVOKABLE void setImageCustomization(const QByteArray &config, const QByteArray &cmdline, const QByteArray &firstrun);
    Q_INVOKABLE void setSavedCustomizationSettings(const QVariantMap &map);
    Q_INVOKABLE QVariantMap getSavedCustomizationSettings();
    Q_INVOKABLE void clearSavedCustomizationSettings();
    Q_INVOKABLE bool hasSavedCustomizationSettings();
    Q_INVOKABLE bool hasKuiper();
    Q_INVOKABLE QByteArray scanProjectList(QString projectPath, QString type);
    Q_INVOKABLE QByteArray getPlatformList( QString type);
    Q_INVOKABLE QByteArray getProjectList();
    Q_INVOKABLE void setProjectSearch(QString val, int index);
    Q_INVOKABLE QString getProjectSearch(int index);
    Q_INVOKABLE bool setupProject(QString binaries, QString project);
    Q_INVOKABLE bool selectProject();
    Q_INVOKABLE void setProjectFiles(QString kernel, QString preloader, QString filelist);
    Q_INVOKABLE bool startProjectConfig();
    Q_INVOKABLE void setProjectListUrl(QString url);
    Q_INVOKABLE QUrl getProjectListUrl();
    Q_INVOKABLE QString crypt(const QByteArray &password);
    Q_INVOKABLE bool compareKuiperJsonVersions();
    Q_INVOKABLE void enableDriveListTimer(bool start);
signals:
    /* We are emiting signals with QVariant as parameters because QML likes it that way */

    void downloadProgress(QVariant dlnow, QVariant dltotal);
    void verifyProgress(QVariant now, QVariant total);
    void error(QVariant msg);
    void success();
    void fileSelected(QVariant filename);
    void cancelled();
    void finalizing();
    void networkOnline();
    void preparationStatusUpdate(QVariant msg);
    void driveListTimeout();

protected slots:

    void startProgressPolling();
    void stopProgressPolling();
    void pollProgress();
    void pollNetwork();
    void syncTime();
    void onSuccess();
    void onError(QString msg);
    void onFileSelected(QString filename);
    void onCancelled();
    void onCacheFileUpdated(QByteArray sha256);
    void onFinalizing();
    void onTimeSyncReply(QNetworkReply *reply);
    void onPreparationStatusUpdate(QString msg);

protected:
    QUrl _src, _repo, _proj, _projlist;
    QString _dst, _cacheFileName, _parentCategory, _osName;
    QString _projectConfig[3];
    QString _kernel, _preloader;
    QStringList _filelist;
    QStringList _binaries, _mountpoints;
    QByteArray _expectedHash, _cachedFileHash, _cmdline, _config, _firstrun;
    quint64 _downloadLen, _extrLen, _devLen, _dlnow, _verifynow;
    DriveListModel _drivelist;
    QQmlApplicationEngine *_engine;
    QTimer _polltimer, _networkchecktimer, _drivelisttimer;
    PowerSaveBlocker _powersave;
    DownloadThread *_thread;
    bool _verifyEnabled, _multipleFilesInZip, _skipFormat, _cachingEnabled, _embeddedMode, _online;
    QSettings _settings;
#ifdef Q_OS_WIN
    QWinTaskbarButton *_taskbarButton;
#endif
    QString _project;
    /*
     *  altera preloader variables
     */
    static const qint64 _sectorSize = 512;
    static const qint64 _startSector = 4202496;
    static const qint64 _numSectors = 8192;

    void _parseCompressedFile();
    QString _getsStorageInfo(QString name, QString type);
    void setupBootWrite();
private:
    int compareVersions(std::string v1, std::string v2);
    bool handlePreloader(QString preloader, QString boot);
};

#endif // IMAGEWRITER_H
