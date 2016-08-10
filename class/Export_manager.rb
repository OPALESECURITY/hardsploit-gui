#===================================================
#  Hardsploit GUI - By Opale Security
#  www.opale-security.com || www.hardsploit.io
#  License: GNU General Public License v3
#  License URI: http://www.gnu.org/licenses/gpl.txt
#===================================================

require 'csv'
class Export_manager < Qt::Widget
  slots 'save_result()'

  def initialize(bus, result, spiDataSended = [])
    super()
    @view = Ui_Export_manager.new
    centerWindow(self)
    @view.setupUi(self)
    @bus = bus
    # Check the bus type to adapt the table column
    if bus == 'SPI'
      create_result_table('SPI')
      @view.cbx_export.hide
      @view.tbl_result.setRowCount(result.length)
      result.length.times do |i|
        @view.tbl_result.setItem(i, 0, Qt::TableWidgetItem.new(spiDataSended[i].to_s))
        @view.tbl_result.setItem(i, 1, Qt::TableWidgetItem.new(result[i].to_s))
      end
      @view.tbl_result.resizeColumnsToContents
      @view.tbl_result.resizeRowsToContents
      @view.tbl_result.horizontalHeader.stretchLastSection = true
    else
      create_result_table('I2C')
      @view.tbl_result.setRowCount(result.length / 2)
      (0..result.length - 1).step(2).each_with_index do |i, v|
        case result[i]
        when 0
          @view.tbl_result.setItem(v, 0, Qt::TableWidgetItem.new('Write'))
          @view.tbl_result.setItem(v, 1, Qt::TableWidgetItem.new('ACK'))
          @view.tbl_result.setItem(v, 2, Qt::TableWidgetItem.new(result[i + 1].to_s))
        when 1
          @view.tbl_result.setItem(v, 0, Qt::TableWidgetItem.new('Read'))
          @view.tbl_result.setItem(v, 1, Qt::TableWidgetItem.new('ACK'))
          @view.tbl_result.setItem(v, 2, Qt::TableWidgetItem.new(result[i + 1].to_s))
        when 2
          @view.tbl_result.setItem(v, 0, Qt::TableWidgetItem.new('Write'))
          @view.tbl_result.setItem(v, 1, Qt::TableWidgetItem.new('NACK'))
          @view.tbl_result.setItem(v, 2, Qt::TableWidgetItem.new(result[i + 1].to_s))
        else
          @view.tbl_result.setItem(v, 0, Qt::TableWidgetItem.new('Write'))
          @view.tbl_result.setItem(v, 1, Qt::TableWidgetItem.new('NACK'))
          @view.tbl_result.setItem(v, 2, Qt::TableWidgetItem.new(result[i + 1].to_s))
        end
      end
      @view.tbl_result.resizeColumnsToContents
      @view.tbl_result.resizeRowsToContents
      @view.tbl_result.horizontalHeader.stretchLastSection = true
    end
  end

  def create_result_table(bus)
    if bus == 'SPI'
      @view.tbl_result.insertColumn(0)
      @view.tbl_result.setHorizontalHeaderItem(0, Qt::TableWidgetItem.new('Data send'))
      @view.tbl_result.insertColumn(1)
      @view.tbl_result.setHorizontalHeaderItem(1, Qt::TableWidgetItem.new('Data receive'))
    else
      @view.tbl_result.insertColumn(0)
      @view.tbl_result.setHorizontalHeaderItem(0, Qt::TableWidgetItem.new('R/W'))
      @view.tbl_result.insertColumn(1)
      @view.tbl_result.setHorizontalHeaderItem(1, Qt::TableWidgetItem.new('(N)ACK)'))
      @view.tbl_result.insertColumn(2)
      @view.tbl_result.setHorizontalHeaderItem(2, Qt::TableWidgetItem.new('DATA'))
    end
  end

  def save_result
    result_file = Qt::FileDialog.getSaveFileName(self, tr('Create a file'), '/', tr('All files (*)'))
    unless result_file.nil?
      if @bus == 'I2C'
        if @view.cbx_export.currentIndex == 0
          save_i2c_csv(result_file)
        else
          save_i2c(result_file)
        end
      else
        save_spi(result_file)
      end
    end
  rescue Exception => msg
    logger = Logger.new($logFilePath)
    logger.error msg
    Qt::MessageBox.new(Qt::MessageBox::Critical, 'Critical error', 'Error occured while saving the results. Consult the logs for more details').exec
  end

  def save_i2c_csv(result_file)
    CSV.open("#{result_file}.csv", 'wb', :col_sep => ';') do |csv|
      csv << ['R/W', '(N)ACK', 'DATA']
      @view.tbl_result.rowCount.times do |i|
        csv << [@view.tbl_result.item(i, 0).text, @view.tbl_result.item(i, 1).text, @view.tbl_result.item(i, 2).text]
      end
    end
  end

  def save_i2c(result_file)
    file = File.open("#{result_file}", 'w')
    result = []
    @view.tbl_result.rowCount.times do |i|
      if @view.tbl_result.item(i, 0).text == 'Read' && @view.tbl_result.item(i, 1).text == 'ACK'
        result.push(@view.tbl_result.item(i, 2).text.to_i)
      end
    end
    file.write(result.pack('C*'))
    file.close
  end

  def save_spi(result_file)
    file = File.open("#{result_file}", 'w')
    result = []
    @view.tbl_result.rowCount.times do |i|
      result.push(@view.tbl_result.item(i, 1).text.to_i)
    end
    file.write(result.pack('C*'))
    file.close
  end
end
