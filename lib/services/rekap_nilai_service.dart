import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RekapNilaiService {
  Future<String?> downloadRekapSiswa({
    required String namaSiswa,
    required String nis,
    required String namaKelas,
    required String namaMapel,
    required String semester,
    required String tahunAjaran,
    required double rataMateri,
    required double rataPraktikum,
    required double nilaiAkhir,
    required List<Map<String, dynamic>> historyNilai,
  }) async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) return null;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Laporan Nilai'];
      excel.delete('Sheet1');

      // ── Style ────────────────────────────────────────────────────
      final navyBg = ExcelColor.fromHexString('#0F2D5C');
      final whiteFg = ExcelColor.fromHexString('#FFFFFF');
      final softBg = ExcelColor.fromHexString('#F8FAFC');
      final blueBg = ExcelColor.fromHexString('#E0F2FE');
      final blueFg = ExcelColor.fromHexString('#075985');
      final amberBg = ExcelColor.fromHexString('#FEF3E0');
      final amberFg = ExcelColor.fromHexString('#92400E');
      final greenFg = ExcelColor.fromHexString('#059669');
      final orangeFg = ExcelColor.fromHexString('#D97706');
      final skyFg = ExcelColor.fromHexString('#0EA5E9');
      final mutedFg = ExcelColor.fromHexString('#6B7280');
      final darkFg = ExcelColor.fromHexString('#1A1F36');

      CellStyle headerStyle() => CellStyle(
        bold: true,
        backgroundColorHex: navyBg,
        fontColorHex: whiteFg,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      CellStyle labelStyle() => CellStyle(bold: true, fontColorHex: darkFg);

      CellStyle mutedStyle() => CellStyle(fontColorHex: mutedFg);

      // ── Header Sekolah ───────────────────────────────────────────
      sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('E1'));
      final sekolahCell = sheet.cell(CellIndex.indexByString('A1'));
      sekolahCell.value = TextCellValue('SMK MITRA PERMATA');
      sekolahCell.cellStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: whiteFg,
        backgroundColorHex: navyBg,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      sheet.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('E2'));
      final subJudulCell = sheet.cell(CellIndex.indexByString('A2'));
      subJudulCell.value = TextCellValue('Laporan Nilai Tugas Harian');
      subJudulCell.cellStyle = CellStyle(
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('#93C5FD'),
        backgroundColorHex: navyBg,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // ── Info Siswa ───────────────────────────────────────────────
      final infoData = [
        ['Nama Siswa', namaSiswa],
        ['NIS', nis],
        ['Kelas', namaKelas],
        ['Mata Pelajaran', namaMapel],
        ['Semester', 'Semester $semester  —  $tahunAjaran'],
      ];

      for (int i = 0; i < infoData.length; i++) {
        final row = i + 4;

        final cellLabel = sheet.cell(CellIndex.indexByString('A$row'));
        cellLabel.value = TextCellValue(infoData[i][0]);
        cellLabel.cellStyle = CellStyle(
          fontSize: 11,
          fontColorHex: mutedFg,
          backgroundColorHex: i % 2 == 0
              ? ExcelColor.fromHexString('#FFFFFF')
              : ExcelColor.fromHexString('#F8FAFC'),
        );

        sheet.merge(
          CellIndex.indexByString('B$row'),
          CellIndex.indexByString('E$row'),
        );
        final cellValue = sheet.cell(CellIndex.indexByString('B$row'));
        cellValue.value = TextCellValue(infoData[i][1]);
        cellValue.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          fontColorHex: darkFg,
          backgroundColorHex: i % 2 == 0
              ? ExcelColor.fromHexString('#FFFFFF')
              : ExcelColor.fromHexString('#F8FAFC'),
        );
      }

      // ── Label Ringkasan ──────────────────────────────────────────
      sheet.merge(
        CellIndex.indexByString('A10'),
        CellIndex.indexByString('E10'),
      );
      final ringkasanLabel = sheet.cell(CellIndex.indexByString('A10'));
      ringkasanLabel.value = TextCellValue('RINGKASAN NILAI');
      ringkasanLabel.cellStyle = CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: mutedFg,
        backgroundColorHex: softBg,
        horizontalAlign: HorizontalAlign.Left,
      );

      // ── Header Ringkasan ─────────────────────────────────────────
      final ringkasanHeaders = [
        'Rata-rata Teori',
        'Rata-rata Praktikum',
        'Nilai Tugas',
        'Nilai Tugas Harian',
        '',
      ];
      for (int i = 0; i < ringkasanHeaders.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 10),
        );
        cell.value = TextCellValue(ringkasanHeaders[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          fontColorHex: mutedFg,
          backgroundColorHex: softBg,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // ── Nilai Ringkasan ──────────────────────────────────────────
      final nilaiTugas = (rataMateri * 0.30) + (rataPraktikum * 0.70);

      String nilaiColorHex;
      if (nilaiAkhir >= 80) {
        nilaiColorHex = '#059669';
      } else if (nilaiAkhir >= 60) {
        nilaiColorHex = '#D97706';
      } else {
        nilaiColorHex = '#DC2626';
      }

      final ringkasanValues = [
        [rataMateri, '#0EA5E9'],
        [rataPraktikum, '#D97706'],
        [nilaiTugas, '#1A1F36'],
        [nilaiAkhir, nilaiColorHex],
      ];

      for (int i = 0; i < ringkasanValues.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 11),
        );
        cell.value = DoubleCellValue(ringkasanValues[i][0] as double);
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 13,
          fontColorHex: ExcelColor.fromHexString(
            ringkasanValues[i][1] as String,
          ),
          backgroundColorHex: i == 3
              ? ExcelColor.fromHexString('#F0FDF4')
              : ExcelColor.fromHexString('#FFFFFF'),
          horizontalAlign: HorizontalAlign.Center,
          verticalAlign: VerticalAlign.Center,
        );
      }

      // Keterangan bobot di bawah nilai akhir
      final bawahNilaiAkhir = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 12),
      );
      bawahNilaiAkhir.value = TextCellValue('bobot 40% rapor');
      bawahNilaiAkhir.cellStyle = CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString('#166534'),
        backgroundColorHex: ExcelColor.fromHexString('#F0FDF4'),
        horizontalAlign: HorizontalAlign.Center,
      );

      // ── Label History ────────────────────────────────────────────
      sheet.merge(
        CellIndex.indexByString('A14'),
        CellIndex.indexByString('E14'),
      );
      final historyLabel = sheet.cell(CellIndex.indexByString('A14'));
      historyLabel.value = TextCellValue('HISTORY NILAI');
      historyLabel.cellStyle = CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: mutedFg,
        backgroundColorHex: softBg,
        horizontalAlign: HorizontalAlign.Left,
      );

      // ── Header History ───────────────────────────────────────────
      final historyHeaders = ['No', 'Judul Tugas', 'Tipe', 'Metode', 'Nilai'];
      for (int i = 0; i < historyHeaders.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 14),
        );
        cell.value = TextCellValue(historyHeaders[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          fontColorHex: mutedFg,
          backgroundColorHex: softBg,
          horizontalAlign: i == 0 || i >= 2
              ? HorizontalAlign.Center
              : HorizontalAlign.Left,
        );
      }

      // ── Isi History ──────────────────────────────────────────────
      for (int i = 0; i < historyNilai.length; i++) {
        final item = historyNilai[i];
        final tugas = item['tugas'];
        final rowIndex = 15 + i;
        final nilai = (item['nilai'] as num).toDouble();
        final isPraktikum = tugas?['type_tugas'] == 'praktikum';

        final rowBg = i % 2 == 0
            ? ExcelColor.fromHexString('#FFFFFF')
            : ExcelColor.fromHexString('#F8FAFC');

        String itemNilaiColorHex;
        if (nilai >= 80) {
          itemNilaiColorHex = '#059669';
        } else if (nilai >= 60) {
          itemNilaiColorHex = '#D97706';
        } else {
          itemNilaiColorHex = '#DC2626';
        }

        // No
        final cellNo = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
        );
        cellNo.value = IntCellValue(i + 1);
        cellNo.cellStyle = CellStyle(
          fontSize: 11,
          fontColorHex: mutedFg,
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Judul Tugas
        final cellJudul = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
        );
        cellJudul.value = TextCellValue(tugas?['judul_tugas'] ?? '-');
        cellJudul.cellStyle = CellStyle(
          fontSize: 11,
          fontColorHex: darkFg,
          backgroundColorHex: rowBg,
        );

        // Tipe
        final cellTipe = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
        );
        cellTipe.value = TextCellValue(isPraktikum ? 'Praktikum' : 'Teori');
        cellTipe.cellStyle = CellStyle(
          fontSize: 11,
          bold: true,
          fontColorHex: isPraktikum ? amberFg : blueFg,
          backgroundColorHex: isPraktikum ? amberBg : blueBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Metode
        final cellMetode = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
        );
        cellMetode.value = TextCellValue(
          tugas?['metode'] == 'upload' ? 'Upload' : 'Manual',
        );
        cellMetode.cellStyle = CellStyle(
          fontSize: 11,
          fontColorHex: mutedFg,
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );

        // Nilai
        final cellNilai = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
        );
        cellNilai.value = DoubleCellValue(nilai);
        cellNilai.cellStyle = CellStyle(
          bold: true,
          fontSize: 11,
          fontColorHex: ExcelColor.fromHexString(itemNilaiColorHex),
          backgroundColorHex: rowBg,
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // ── Footer ───────────────────────────────────────────────────
      final footerRow = 16 + historyNilai.length;
      sheet.merge(
        CellIndex.indexByString('A$footerRow'),
        CellIndex.indexByString('C$footerRow'),
      );
      final footerLeft = sheet.cell(CellIndex.indexByString('A$footerRow'));
      footerLeft.value = TextCellValue('SMK Mitra Permata');
      footerLeft.cellStyle = CellStyle(
        fontSize: 10,
        fontColorHex: mutedFg,
        backgroundColorHex: softBg,
      );

      sheet.merge(
        CellIndex.indexByString('D$footerRow'),
        CellIndex.indexByString('E$footerRow'),
      );
      final footerRight = sheet.cell(CellIndex.indexByString('D$footerRow'));
      footerRight.value = TextCellValue(tahunAjaran);
      footerRight.cellStyle = CellStyle(
        fontSize: 10,
        fontColorHex: mutedFg,
        backgroundColorHex: softBg,
        horizontalAlign: HorizontalAlign.Right,
      );

      // ── Row & Column Size ─────────────────────────────────────────
      sheet.setRowHeight(0, 28); // header sekolah
      sheet.setRowHeight(1, 20); // sub judul
      sheet.setColumnWidth(0, 6);
      sheet.setColumnWidth(1, 35);
      sheet.setColumnWidth(2, 15);
      sheet.setColumnWidth(3, 12);
      sheet.setColumnWidth(4, 10);

      // ── Simpan File ───────────────────────────────────────────────
      final bytes = excel.encode();
      if (bytes == null) return null;

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final fileName =
          'Nilai_${namaSiswa}_${namaMapel}_Sem${semester}_${tahunAjaran.replaceAll('/', '-')}.xlsx'
              .replaceAll(' ', '_');

      final file = File('${dir!.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}
