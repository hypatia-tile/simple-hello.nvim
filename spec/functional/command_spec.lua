describe("SimpleHello command #functional", function()
   before_each(function()
      -- Ensure plugin is loaded by setting runtimepath
      local plugin_path = vim.fn.getcwd()
      vim.cmd("set runtimepath^=" .. plugin_path)

      -- Source the plugin file to register the command
      vim.cmd("runtime plugin/simple-hello.lua")
   end)

   describe("command registration", function()
      it("creates SimpleHello command", function()
         local commands = vim.api.nvim_get_commands({})
         assert.is_not_nil(commands.SimpleHello)
      end)

      it("command has correct attributes", function()
         local commands = vim.api.nvim_get_commands({})
         local cmd = commands.SimpleHello

         assert.is_not_nil(cmd)
         assert.is_table(cmd)
      end)
   end)

   describe("command execution", function()
      it("executes without error", function()
         assert.has_no.errors(function()
            vim.cmd("SimpleHello")
         end)
      end)

      it("calls the module's hello function", function()
         -- Load module and spy on it
         local simple_hello = require("simple-hello")
         local hello_spy = spy.on(simple_hello, "hello")

         -- Execute command
         vim.cmd("SimpleHello")

         -- Verify hello was called
         assert.spy(hello_spy).was_called()
         assert.spy(hello_spy).was_called(1)

         hello_spy:revert()
      end)

      it("prints message when executed", function()
         local captured = nil
         local original_print = _G.print

         -- Mock print to capture output
         _G.print = function(msg)
            captured = msg
         end

         vim.cmd("SimpleHello")

         -- Restore original print
         _G.print = original_print

         -- Verify message was printed
         assert.is_not_nil(captured)
         assert.matches("Hello", captured)
      end)
   end)

   describe("plugin integration", function()
      it("can be called multiple times", function()
         assert.has_no.errors(function()
            vim.cmd("SimpleHello")
            vim.cmd("SimpleHello")
            vim.cmd("SimpleHello")
         end)
      end)

      it("works in different buffer contexts", function()
         -- Create a new buffer
         vim.cmd("enew")
         local buf1 = vim.api.nvim_get_current_buf()

         assert.has_no.errors(function()
            vim.cmd("SimpleHello")
         end)

         -- Create another buffer
         vim.cmd("enew")
         local buf2 = vim.api.nvim_get_current_buf()

         assert.has_no.errors(function()
            vim.cmd("SimpleHello")
         end)

         -- Verify buffers are different
         assert.is_not.equal(buf1, buf2)
      end)
   end)
end)
