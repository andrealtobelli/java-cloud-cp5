package com.dimdim.controller;

import com.dimdim.model.Empresa;
import com.dimdim.model.Funcionario;
import com.dimdim.repository.EmpresaRepository;
import com.dimdim.repository.FuncionarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@Controller
@RequestMapping("/empresas")
public class EmpresaController {
    @Autowired
    private EmpresaRepository empresaRepository;
    @Autowired
    private FuncionarioRepository funcionarioRepository;

    @GetMapping
    public String listarEmpresas(Model model) {
        model.addAttribute("empresas", empresaRepository.findAll());
        return "empresas";
    }

    @GetMapping("/nova")
    public String novaEmpresaForm(Model model) {
        model.addAttribute("empresa", new Empresa());
        return "empresa-form";
    }

    @PostMapping
    public String salvarEmpresa(@ModelAttribute Empresa empresa) {
        empresaRepository.save(empresa);
        return "redirect:/empresas";
    }

    @GetMapping("/editar/{id}")
    public String editarEmpresaForm(@PathVariable Long id, Model model) {
        Optional<Empresa> empresa = empresaRepository.findById(id);
        if (empresa.isPresent()) {
            model.addAttribute("empresa", empresa.get());
            return "empresa-form";
        }
        return "redirect:/empresas";
    }

    @PostMapping("/editar/{id}")
    public String atualizarEmpresa(@PathVariable Long id, @ModelAttribute Empresa empresa) {
        Optional<Empresa> empresaExistente = empresaRepository.findById(id);
        if (empresaExistente.isPresent()) {
            Empresa e = empresaExistente.get();
            // Se nome vier nulo do formulário, mantém o nome atual
            if (empresa.getNome() != null) {
                e.setNome(empresa.getNome());
            }
            empresaRepository.save(e);
        }
        return "redirect:/empresas";
    }

    @GetMapping("/excluir/{id}")
    public String excluirEmpresa(@PathVariable Long id) {
        empresaRepository.deleteById(id);
        return "redirect:/empresas";
    }

    @GetMapping("/{id}/funcionarios")
    public String listarFuncionarios(@PathVariable Long id, Model model) {
        Optional<Empresa> empresa = empresaRepository.findById(id);
        if (empresa.isPresent()) {
            List<Funcionario> funcionarios = empresa.get().getFuncionarios();
            model.addAttribute("empresa", empresa.get());
            model.addAttribute("funcionarios", funcionarios);
            return "funcionarios";
        }
        return "redirect:/empresas";
    }
}
